import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/follow.dart';
import '../models/notification.dart';
import '../models/user_profile.dart';
import 'notifications_repo.dart';

/// Seguimientos entre personas.
///
/// - `follows/{follower}_{followed}`: quién sigue a quién, con los datos de
///   ambas personas copiados para pintar las listas sin leer perfiles.
/// - `users/{uid}.followersCount` y `followingCount`: se mueven en la misma
///   transacción que crea o borra el seguimiento.
class FollowRepo {
  FollowRepo(this._db, this._notifications);

  final FirebaseFirestore _db;
  final NotificationsRepo _notifications;

  CollectionReference<Map<String, dynamic>> get _follows =>
      _db.collection('follows');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<bool> isFollowing(String me, String other) => _follows
      .doc(FollowEdge.docId(me, other))
      .snapshots()
      .map((s) => s.exists);

  Future<bool> checkFollowing(String me, String other) async =>
      (await _follows.doc(FollowEdge.docId(me, other)).get()).exists;

  List<FollowEdge> _edges(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => FollowEdge.fromMap(d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Quiénes siguen a `uid`, de la más reciente a la más antigua.
  Stream<List<PersonInfo>> followers(String uid) => _follows
      .where('followed', isEqualTo: uid)
      .snapshots()
      .map((s) => _edges(s).map((e) => e.followerInfo).toList());

  /// A quiénes sigue `uid`.
  Stream<List<PersonInfo>> following(String uid) => _follows
      .where('follower', isEqualTo: uid)
      .snapshots()
      .map((s) => _edges(s).map((e) => e.followedInfo).toList());

  /// Solo los uids seguidos (para la actividad del inicio).
  Stream<List<String>> followingIds(String uid) => _follows
      .where('follower', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .map((d) => (d.data()['followed'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort());

  /// Seguir (`follow: true`) o dejar de seguir a `other`. Idempotente: si ya
  /// estaba así no escribe nada. Seguir crea la notificación "X empezó a
  /// seguirte"; dejar de seguir la quita.
  Future<void> setFollowing({
    required UserProfile me,
    required PersonInfo other,
    required bool follow,
  }) async {
    if (me.uid == other.uid) return;
    final edgeRef = _follows.doc(FollowEdge.docId(me.uid, other.uid));
    final meRef = _users.doc(me.uid);
    final otherRef = _users.doc(other.uid);
    final notificationId = AppNotification.idFor(
      to: other.uid,
      type: NotificationType.follow,
      from: me.uid,
    );

    await _db.runTransaction((tx) async {
      final edgeSnap = await tx.get(edgeRef);
      final delta = followDelta(
        me: me.uid,
        other: other.uid,
        exists: edgeSnap.exists,
        follow: follow,
      );
      if (delta.isNoop) return;

      if (delta.createEdge) {
        tx.set(edgeRef, {
          'follower': me.uid,
          'followed': other.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'followerInfo': me.person.toMap(),
          'followedInfo': other.toMap(),
        });
        _notifications.putIn(
          tx,
          AppNotification(
            id: notificationId,
            to: other.uid,
            from: me.person,
            type: NotificationType.follow,
            createdAt: DateTime.now(),
            read: false,
          ),
        );
      } else {
        tx.delete(edgeRef);
        _notifications.removeIn(tx, notificationId);
      }
      tx.set(
        meRef,
        {'followingCount': FieldValue.increment(delta.followingDelta)},
        SetOptions(merge: true),
      );
      tx.set(
        otherRef,
        {'followersCount': FieldValue.increment(delta.followersDelta)},
        SetOptions(merge: true),
      );
    });
  }

  /// Propaga nombre, color, foto y @usuario de una persona a todos sus
  /// seguimientos (en los dos sentidos), como hace `UserRepo` con las notas.
  Future<void> propagatePerson(PersonInfo person) async {
    final asFollower =
        await _follows.where('follower', isEqualTo: person.uid).get();
    final asFollowed =
        await _follows.where('followed', isEqualTo: person.uid).get();
    var batch = _db.batch();
    var pending = 0;
    Future<void> flush() async {
      if (pending == 0) return;
      await batch.commit();
      batch = _db.batch();
      pending = 0;
    }

    for (final d in asFollower.docs) {
      batch.update(d.reference, {'followerInfo': person.toMap()});
      if (++pending == 400) await flush();
    }
    for (final d in asFollowed.docs) {
      batch.update(d.reference, {'followedInfo': person.toMap()});
      if (++pending == 400) await flush();
    }
    await flush();
  }
}
