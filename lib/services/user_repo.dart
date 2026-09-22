import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart' show ThemeMode;

import '../models/album.dart';
import '../models/artist.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';

class UserRepo {
  UserRepo(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<UserProfile?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? UserProfile.fromDoc(s) : null);

  Future<UserProfile?> fetch(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.exists ? UserProfile.fromDoc(snap) : null;
  }

  Future<void> create({
    required String uid,
    required String name,
    required int colorValue,
    String? avatarUrl,
  }) {
    return _users.doc(uid).set({
      'name': name.trim(),
      'color': colorValue,
      'avatarUrl': avatarUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'ratingsCount': 0,
      'ratingsSum': 0,
      'favorites': <Map<String, dynamic>>[],
      'recentSearches': <String>[],
    });
  }

  /// Actualiza el perfil y propaga nombre/color/foto a todas sus notas,
  /// que los guardan denormalizados para pintar el feed. El banner solo se
  /// toca si `updateBanner` es true (null borra la foto de fondo).
  Future<void> updateProfile(
    RaterInfo info, {
    String? bannerUrl,
    bool updateBanner = false,
  }) async {
    await _users.doc(info.uid).set({
      'name': info.name.trim(),
      'color': info.colorValue,
      'avatarUrl': info.avatarUrl,
      if (updateBanner) 'bannerUrl': bannerUrl,
    }, SetOptions(merge: true));

    final ratings = await _db
        .collection('ratings')
        .where('uid', isEqualTo: info.uid)
        .get();
    var batch = _db.batch();
    var pending = 0;
    for (final doc in ratings.docs) {
      batch.update(doc.reference, {'user': info.toMap()});
      pending++;
      if (pending == 400) {
        await batch.commit();
        batch = _db.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();
  }

  /// Cambia el color de la persona (avatar, resplandor y énfasis de su app)
  /// y lo propaga a sus notas como hace `updateProfile`.
  Future<void> setColor(UserProfile profile, int colorValue) {
    return updateProfile(
      RaterInfo(
        uid: profile.uid,
        name: profile.name,
        colorValue: colorValue,
        avatarUrl: profile.avatarUrl,
      ),
    );
  }

  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadBanner(String uid, Uint8List bytes) async {
    final ref = _storage.ref('banners/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  static const int maxFavorites = 3;

  Future<void> setFavorites(String uid, List<Album> albums) {
    return _users.doc(uid).set({
      'favorites': albums.take(maxFavorites).map((a) => a.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  Future<void> setFavoriteArtists(String uid, List<Artist> artists) {
    return _users.doc(uid).set({
      'favoriteArtists':
          artists.take(maxFavorites).map((a) => a.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  Future<void> setThemeMode(String uid, ThemeMode mode) {
    return _users.doc(uid).set(
      {'theme': themeModeKey(mode)},
      SetOptions(merge: true),
    );
  }

  Future<void> rememberSearch(String uid, String query, List<String> current) {
    final q = query.trim();
    if (q.isEmpty) return Future.value();
    final next = [
      q,
      ...current.where((s) => s.toLowerCase() != q.toLowerCase()),
    ].take(8).toList();
    return _users.doc(uid).set({'recentSearches': next}, SetOptions(merge: true));
  }
}
