import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/album.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';

/// Notas y agregados por álbum en Firestore.
///
/// - `ratings/{uid}_{albumId}`: una nota por persona y álbum.
/// - `albums/{albumId}`: copia compacta del álbum + conteo, suma e histograma.
/// - `users/{uid}`: conteo y suma de la persona.
///
/// Los agregados se mantienen con una transacción para que promedio e
/// histograma siempre cuadren con las notas.
class RatingsRepo {
  RatingsRepo(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _db.collection('ratings');
  CollectionReference<Map<String, dynamic>> get _albums =>
      _db.collection('albums');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  List<RatingEntry> _entries(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(RatingEntry.fromDoc).toList();

  List<RatingEntry> _newestFirst(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = _entries(snap);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Stream<List<RatingEntry>> feed({int limit = 30}) => _ratings
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(_entries);

  Stream<List<AlbumStats>> recentlyRated({int limit = 12}) => _albums
      .orderBy('lastRatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map(AlbumStats.fromDoc).where((a) => a.count > 0).toList());

  Stream<List<AlbumStats>> mostRated({int limit = 12}) => _albums
      .orderBy('ratingsCount', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map(AlbumStats.fromDoc).where((a) => a.count > 0).toList());

  Stream<AlbumStats?> albumStats(String albumId) => _albums
      .doc(albumId)
      .snapshots()
      .map((s) => s.exists ? AlbumStats.fromDoc(s) : null);

  Stream<RatingEntry?> myRating(String uid, String albumId) => _ratings
      .doc(RatingEntry.docId(uid, albumId))
      .snapshots()
      .map((s) => s.exists ? RatingEntry.fromDoc(s) : null);

  Stream<List<RatingEntry>> albumRatings(String albumId, {int limit = 50}) =>
      _ratings
          .where('albumId', isEqualTo: albumId)
          .limit(limit)
          .snapshots()
          .map(_newestFirst);

  Stream<List<RatingEntry>> userRatings(String uid) =>
      _ratings.where('uid', isEqualTo: uid).snapshots().map(_newestFirst);

  Future<List<RatingEntry>> fetchUserRatings(String uid) async =>
      _newestFirst(await _ratings.where('uid', isEqualTo: uid).get());

  Future<void> rate({
    required UserProfile user,
    required Album album,
    required int score,
    required String note,
  }) async {
    final ratingRef = _ratings.doc(RatingEntry.docId(user.uid, album.id));
    final albumRef = _albums.doc(album.id);
    final userRef = _users.doc(user.uid);

    await _db.runTransaction((tx) async {
      final ratingSnap = await tx.get(ratingRef);
      final albumSnap = await tx.get(albumRef);

      final previous = ratingSnap.exists
          ? (ratingSnap.data()!['score'] as num?)?.toInt()
          : null;
      final albumData = albumSnap.data() ?? const <String, dynamic>{};
      var count = (albumData['ratingsCount'] as num?)?.toInt() ?? 0;
      num sum = (albumData['ratingsSum'] as num?) ?? 0;
      final hist = Map<String, dynamic>.from((albumData['hist'] as Map?) ?? {});

      if (previous != null) {
        sum -= previous;
        hist['$previous'] =
            math.max(0, ((hist['$previous'] as num?)?.toInt() ?? 1) - 1);
      } else {
        count += 1;
      }
      sum += score;
      hist['$score'] = ((hist['$score'] as num?)?.toInt() ?? 0) + 1;

      tx.set(
        albumRef,
        {
          ...album.toMap(),
          'ratingsCount': count,
          'ratingsSum': sum,
          'hist': hist,
          'lastRatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        ratingRef,
        {
          'uid': user.uid,
          'albumId': album.id,
          'score': score,
          'note': note,
          'album': album.toMap(),
          'user': user.rater.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (previous == null) 'createdAt': FieldValue.serverTimestamp(),
          if (previous == null) 'likedBy': <String>[],
        },
        SetOptions(merge: true),
      );

      tx.set(
        userRef,
        {
          'ratingsCount': FieldValue.increment(previous == null ? 1 : 0),
          'ratingsSum': FieldValue.increment(score - (previous ?? 0)),
          'lastRatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> remove({required String uid, required String albumId}) async {
    final ratingRef = _ratings.doc(RatingEntry.docId(uid, albumId));
    final albumRef = _albums.doc(albumId);
    final userRef = _users.doc(uid);

    await _db.runTransaction((tx) async {
      final ratingSnap = await tx.get(ratingRef);
      if (!ratingSnap.exists) return;
      final albumSnap = await tx.get(albumRef);

      final previous = (ratingSnap.data()!['score'] as num?)?.toInt() ?? 0;
      final albumData = albumSnap.data() ?? const <String, dynamic>{};
      final count =
          math.max(0, ((albumData['ratingsCount'] as num?)?.toInt() ?? 1) - 1);
      final sum = ((albumData['ratingsSum'] as num?) ?? previous) - previous;
      final hist = Map<String, dynamic>.from((albumData['hist'] as Map?) ?? {});
      hist['$previous'] =
          math.max(0, ((hist['$previous'] as num?)?.toInt() ?? 1) - 1);

      tx.set(
        albumRef,
        {'ratingsCount': count, 'ratingsSum': math.max(0, sum), 'hist': hist},
        SetOptions(merge: true),
      );
      tx.delete(ratingRef);
      tx.set(
        userRef,
        {
          'ratingsCount': FieldValue.increment(-1),
          'ratingsSum': FieldValue.increment(-previous),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> toggleLike(RatingEntry entry, String uid) {
    final liked = entry.likedByMe(uid);
    return _ratings.doc(entry.id).update({
      'likedBy': liked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }
}
