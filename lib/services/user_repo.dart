import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart' show ThemeMode;

import '../models/album.dart';
import '../models/artist.dart';
import '../models/follow.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../util/username.dart';
import 'follow_repo.dart';
import 'lists_repo.dart';
import 'replies_repo.dart';

/// Alguien más tiene ese @usuario.
class UsernameTakenException implements Exception {
  const UsernameTakenException(this.username);

  final String username;

  // El texto para la persona lo arma la interfaz (`l10n.usernameTaken`).
  @override
  String toString() => 'UsernameTakenException(@$username)';
}

class UserRepo {
  UserRepo(
    this._db,
    this._storage, {
    FollowRepo? follows,
    ListsRepo? lists,
    RepliesRepo? replies,
  })  : _follows = follows,
        _lists = lists,
        _replies = replies;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FollowRepo? _follows;
  final ListsRepo? _lists;
  final RepliesRepo? _replies;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// `usernames/{usuario}` → `{uid}`: la reserva que garantiza que un
  /// @usuario sea de una sola persona.
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');

  Stream<UserProfile?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? UserProfile.fromDoc(s) : null);

  Future<UserProfile?> fetch(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.exists ? UserProfile.fromDoc(snap) : null;
  }

  /// De quién es un @usuario (null si nadie lo tiene). Sirve para abrir el
  /// perfil al tocar una mención.
  Future<String?> uidForUsername(String username) async {
    final snap = await _usernames.doc(username.toLowerCase()).get();
    return snap.data()?['uid'] as String?;
  }

  /// True si nadie tiene ese @usuario, o si lo tiene `forUid` (la misma
  /// persona que pregunta). Consulta al servidor para no responder con una
  /// caché vieja; sin conexión lanza.
  Future<bool> isUsernameAvailable(String username, {String? forUid}) async {
    final snap = await _usernames
        .doc(username)
        .get(const GetOptions(source: Source.server));
    if (!snap.exists) return true;
    return snap.data()?['uid'] == forUid;
  }

  /// Reserva `username` para `uid` dentro de la transacción: si otra persona
  /// lo tomó primero, lanza `UsernameTakenException` y no se escribe nada.
  Future<void> _reserveUsername(
    Transaction tx,
    String uid,
    String username,
  ) async {
    final handle = _usernames.doc(username);
    final taken = await tx.get(handle);
    if (taken.exists && taken.data()?['uid'] != uid) {
      throw UsernameTakenException(username);
    }
    tx.set(handle, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
  }

  /// Crea el perfil y reserva su @usuario en una sola transacción.
  Future<void> create({
    required String uid,
    required String name,
    required int colorValue,
    required String username,
    String? avatarUrl,
  }) {
    return _db.runTransaction((tx) async {
      await _reserveUsername(tx, uid, username);
      tx.set(_users.doc(uid), {
        'name': name.trim(),
        'nameLower': UserProfile.searchKey(name),
        'username': username,
        'color': colorValue,
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'ratingsCount': 0,
        'ratingsSum': 0,
        'favorites': <Map<String, dynamic>>[],
        'recentSearches': <String>[],
        'followersCount': 0,
        'followingCount': 0,
      });
    });
  }

  /// Completa `nameLower` en los perfiles creados antes de que existiera la
  /// búsqueda de personas.
  Future<void> ensureSearchFields(UserProfile profile) {
    final key = UserProfile.searchKey(profile.name);
    if (profile.nameLower == key) return Future.value();
    return _users.doc(profile.uid).set({'nameLower': key}, SetOptions(merge: true));
  }

  /// Personas cuyo nombre o @usuario empieza por `query` (sin distinguir
  /// mayúsculas). Con "@" delante busca solo por @usuario. Nunca devuelve a
  /// `excludeUid` (uno mismo).
  Future<List<PersonInfo>> searchPeople(
    String query, {
    String? excludeUid,
    int limit = 10,
  }) async {
    final raw = query.trim().toLowerCase();
    if (raw.isEmpty) return const [];
    final onlyUsername = raw.startsWith('@');
    final username = normalizeUsername(raw);
    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    if (username.isNotEmpty && usernameProblem(username) != UsernameProblem.badChars) {
      futures.add(_users
          .where('username', isGreaterThanOrEqualTo: username)
          .where('username', isLessThan: '$username\uf8ff')
          .limit(limit)
          .get());
    }
    if (!onlyUsername) {
      futures.add(_users
          .where('nameLower', isGreaterThanOrEqualTo: raw)
          .where('nameLower', isLessThan: '$raw\uf8ff')
          .limit(limit)
          .get());
    }
    final found = <String, PersonInfo>{};
    for (final snap in await Future.wait(futures)) {
      for (final doc in snap.docs) {
        if (doc.id == excludeUid) continue;
        found.putIfAbsent(doc.id, () => UserProfile.fromDoc(doc).person);
      }
    }
    final out = found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out.take(limit).toList();
  }

  /// Cambia (o fija por primera vez) el @usuario, liberando el anterior en
  /// la misma transacción.
  Future<void> setUsername(String uid, String username, {String? previous}) {
    if (previous == username) return Future.value();
    return _db.runTransaction((tx) async {
      await _reserveUsername(tx, uid, username);
      tx.set(
        _users.doc(uid),
        {'username': username},
        SetOptions(merge: true),
      );
      if (previous != null) tx.delete(_usernames.doc(previous));
    });
  }

  /// Actualiza el perfil y propaga nombre/color/foto a todas sus notas y
  /// seguimientos, que los guardan denormalizados para pintar el feed y las
  /// listas de personas. El banner solo se toca si `updateBanner` es true
  /// (null borra la foto de fondo). `username` es el @usuario ya guardado,
  /// para copiarlo en los seguimientos.
  Future<void> updateProfile(
    RaterInfo info, {
    String? bannerUrl,
    bool updateBanner = false,
    String? username,
    String? bio,
  }) async {
    await _users.doc(info.uid).set({
      'name': info.name.trim(),
      'nameLower': UserProfile.searchKey(info.name),
      'color': info.colorValue,
      'avatarUrl': info.avatarUrl,
      if (updateBanner) 'bannerUrl': bannerUrl,
      // null = no se tocó; vacía la borra.
      if (bio != null) 'bio': bio.trim(),
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

    final person = PersonInfo(
      uid: info.uid,
      name: info.name.trim(),
      colorValue: info.colorValue,
      username: username,
      avatarUrl: info.avatarUrl,
    );
    await _follows?.propagatePerson(person);
    await _lists?.propagateOwner(person);
    await _replies?.propagateAuthor(person);
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
      username: profile.username,
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

  /// "es", "en" o null para seguir el idioma del teléfono.
  Future<void> setLanguage(String uid, String? language) {
    return _users.doc(uid).set(
      {'language': language ?? 'system'},
      SetOptions(merge: true),
    );
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
