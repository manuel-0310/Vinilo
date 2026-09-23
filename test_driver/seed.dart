// Siembra y borra los perfiles de prueba de `fake_people.dart` con los mismos
// repositorios de la app (transacciones incluidas), para que promedios,
// histogramas y contadores cuadren igual que si lo hubieran hecho personas.
// Corre en segundo plano: `msg seed-status` cuenta cómo va y cada paso sale
// en el log con el prefijo SEED.
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/artist.dart';
import 'package:no_retiene/models/music_list.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/user_profile.dart';
import 'package:no_retiene/services/account_service.dart';
import 'package:no_retiene/services/auth_service.dart';
import 'package:no_retiene/services/follow_repo.dart';
import 'package:no_retiene/services/lists_repo.dart';
import 'package:no_retiene/services/notifications_repo.dart';
import 'package:no_retiene/services/ratings_repo.dart';
import 'package:no_retiene/services/spotify_api.dart';
import 'package:no_retiene/services/user_repo.dart';

import 'fake_people.dart';

/// Estado de la última tarea (`idle`, `running …`, `done …`, `error …`).
String seedStatus = 'idle';
bool _busy = false;

void _log(String line) {
  // ignore: avoid_print
  print('SEED $line');
}

/// Lanza la tarea sin esperarla (el driver no aguanta peticiones largas).
String startSeed() => _start('seed', _seed);

String startDeleteFakePeople() => _start('delete', _deleteAll);

String _start(String name, Future<String> Function() task) {
  if (_busy) return 'busy: $seedStatus';
  _busy = true;
  seedStatus = 'running $name';
  task().then((result) {
    seedStatus = 'done $name: $result';
    _log(seedStatus);
  }).catchError((Object e, StackTrace st) {
    seedStatus = 'error $name: $e';
    _log('$seedStatus\n$st');
  }).whenComplete(() => _busy = false);
  return 'started $name';
}

class _Repos {
  _Repos() {
    final db = FirebaseFirestore.instance;
    final notifications = NotificationsRepo(db);
    users = UserRepo(db, FirebaseStorage.instance);
    ratings = RatingsRepo(db, notifications);
    lists = ListsRepo(db, notifications);
    follows = FollowRepo(db, notifications);
    spotify = SpotifyApi(
      baseUrl: SpotifyApi.configuredUrl,
      idToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  }

  late final UserRepo users;
  late final RatingsRepo ratings;
  late final ListsRepo lists;
  late final FollowRepo follows;
  late final SpotifyApi spotify;
}

// Lecturas siempre del servidor: con la app escuchando el perfil de la
// sesión, un get() normal puede devolver la copia local de antes de crearlo.
const _server = GetOptions(source: Source.server);

Future<UserProfile?> _profile(String uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get(_server);
  return doc.exists ? UserProfile.fromDoc(doc) : null;
}

Future<List<RatingEntry>> _ratingsOf(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('ratings')
      .where('uid', isEqualTo: uid)
      .get(_server);
  final out = snap.docs.map(RatingEntry.fromDoc).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return out;
}

Future<List<MusicList>> _listsOf(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('lists')
      .where('ownerUid', isEqualTo: uid)
      .get(_server);
  final out = snap.docs.map(MusicList.fromDoc).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return out;
}

/// Como `_profile`, pero reintenta unos segundos (un perfil recién creado
/// puede tardar en verse).
Future<UserProfile> _profileEventually(String uid) async {
  for (var i = 0; i < 20; i++) {
    final profile = await _profile(uid);
    if (profile != null) return profile;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('No aparece el perfil $uid');
}

/// Entra con la cuenta de prueba o la crea si no existe. Devuelve el uid.
Future<String> _signInOrUp(String email) async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser?.email == email) return auth.currentUser!.uid;
  if (auth.currentUser != null) await auth.signOut();
  try {
    final cred = await auth.signInWithEmailAndPassword(email: email, password: fakePassword);
    return cred.user!.uid;
  } on FirebaseAuthException catch (e) {
    if (e.code != 'user-not-found' && e.code != 'invalid-credential' && e.code != 'INVALID_LOGIN_CREDENTIALS') {
      rethrow;
    }
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: fakePassword);
    return cred.user!.uid;
  }
}

Future<String> _seed() async {
  final r = _Repos();
  final uids = <String, String>{};

  // 1. Cada persona: perfil, notas, favoritos y listas.
  for (final p in fakePeople) {
    final uid = await _signInOrUp(p.email);
    uids[p.username] = uid;
    var profile = await _profile(uid);
    if (profile == null) {
      await r.users.create(uid: uid, name: p.name, colorValue: p.colorValue, username: p.username);
      // Justo después de crearlo la lectura a veces todavía no lo ve: se
      // arma con los mismos datos que se acaban de guardar.
      profile = UserProfile(
        uid: uid,
        name: p.name,
        colorValue: p.colorValue,
        username: p.username,
        createdAt: DateTime.now(),
      );
      _log('${p.username}: perfil creado ($uid)');
    }

    final already = {for (final e in await _ratingsOf(uid)) e.album.id: e.album};
    final byQuery = <String, Album>{};
    for (final rating in p.ratings) {
      final page = await r.spotify.search(rating.query);
      if (page.items.isEmpty) {
        _log('${p.username}: sin resultados para "${rating.query}"');
        continue;
      }
      final album = page.items.first;
      byQuery[rating.query] = album;
      if (already.containsKey(album.id)) continue;
      await r.ratings.rate(user: profile, album: album, score: rating.score, note: rating.note ?? '');
      _log('${p.username}: ${rating.score} · ${album.name} — ${album.artist}');
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    await r.users.setFavorites(uid, [
      for (final q in p.favorites)
        if (byQuery[q] != null) byQuery[q]!,
    ]);
    final artists = <Artist>[];
    for (final name in p.favoriteArtists) {
      final found = await r.spotify.searchArtists(name);
      if (found.isNotEmpty) artists.add(found.first);
    }
    await r.users.setFavoriteArtists(uid, artists);

    final existing = {for (final l in await _listsOf(uid)) l.name};
    final rankingAlbum = byQuery[p.rankingFrom];
    if (rankingAlbum != null && !existing.contains(p.rankingName)) {
      final detail = await r.spotify.album(rankingAlbum.id);
      final tracks = [...detail.tracks]..shuffle(Random(p.rankingSeed));
      await r.lists.create(
        owner: profile,
        name: p.rankingName,
        description: 'Mi orden, sin discusión.',
        kind: ListKind.ranking,
        itemType: ListItemType.tracks,
        items: [for (final t in tracks) ListItem.fromTrack(t, detail)],
      );
      _log('${p.username}: ranking "${p.rankingName}" (${tracks.length})');
    }
    if (!existing.contains(p.albumListName)) {
      await r.lists.create(
        owner: profile,
        name: p.albumListName,
        description: '',
        kind: ListKind.list,
        itemType: ListItemType.albums,
        items: [
          for (final q in p.albumList)
            if (byQuery[q] != null) ListItem.fromAlbum(byQuery[q]!),
        ],
      );
      _log('${p.username}: lista "${p.albumListName}"');
    }
  }

  // 2. Se siguen entre todos, se dan "me gusta" en notas y listas, y tres
  //    siguen a Manuel y le dan "me gusta" a algunas de sus notas.
  final manuel = await _profile(manuelUid);
  if (manuel == null) _log('No existe el perfil de Manuel ($manuelUid): no se le sigue.');
  for (final (i, p) in fakePeople.indexed) {
    final uid = await _signInOrUp(p.email);
    final me = await _profileEventually(uid);
    for (final other in fakePeople) {
      if (other.username == p.username) continue;
      final them = await _profileEventually(uids[other.username]!);
      await r.follows.setFollowing(me: me, other: them.person, follow: true);
    }
    // "Me gusta" a las dos notas con comentario más recientes de las dos
    // personas siguientes, y like y guardar a una lista de cada una.
    for (final step in [1, 2]) {
      final other = fakePeople[(i + step) % fakePeople.length];
      final otherUid = uids[other.username]!;
      final theirs = (await _ratingsOf(otherUid)).where((e) => e.note.isNotEmpty).take(2);
      for (final entry in theirs) {
        if (!entry.likedByMe(uid)) await r.ratings.toggleLike(entry, me);
      }
      final theirLists = await _listsOf(otherUid);
      if (theirLists.isNotEmpty) {
        final list = theirLists[step == 1 ? 0 : theirLists.length - 1];
        if (step == 1 && !list.likedByMe(uid)) await r.lists.toggleLike(list, me);
        if (step == 2 && !list.savedByMe(uid)) await r.lists.toggleSave(list, me);
      }
    }
    if (p.followsManuel && manuel != null) {
      await r.follows.setFollowing(me: me, other: manuel.person, follow: true);
      final his = (await _ratingsOf(manuelUid)).take(3);
      for (final entry in his) {
        if (!entry.likedByMe(uid)) await r.ratings.toggleLike(entry, me);
      }
      _log('${p.username}: sigue a Manuel y le dio "me gusta" a ${his.length} notas');
    }
    _log('${p.username}: sigue a los demás');
  }
  await FirebaseAuth.instance.signOut();
  return fakePeople.map((p) => '@${p.username}').join(' ');
}

/// Borra todos los perfiles de prueba con la función `account` (la misma que
/// "Eliminar cuenta"), que también descuenta los contadores de Manuel y
/// quita sus "me gusta" y notificaciones.
Future<String> _deleteAll() async {
  final auth = FirebaseAuth.instance;
  final account = AccountService(auth: AuthService(), spotifyUrl: SpotifyApi.configuredUrl);
  final done = <String>[];
  for (final p in fakePeople) {
    if (auth.currentUser != null) await auth.signOut();
    try {
      await auth.signInWithEmailAndPassword(email: p.email, password: fakePassword);
    } on FirebaseAuthException catch (e) {
      _log('${p.username}: no existe (${e.code})');
      continue;
    }
    await account.deleteAccount(fakePassword);
    account.deleting = false;
    done.add('@${p.username}');
    _log('${p.username}: cuenta borrada');
  }
  if (auth.currentUser != null) await auth.signOut();
  return done.isEmpty ? 'nada que borrar' : done.join(' ');
}

/// Resumen del perfil de Manuel para comparar antes y después.
Future<String> manuelSnapshot() async {
  final UserProfile? manuel = await _profile(manuelUid);
  if (manuel == null) return 'no-profile';
  final ratings = await _ratingsOf(manuelUid);
  final likes = ratings.fold<int>(0, (s, e) => s + e.likedBy.length);
  return 'user=@${manuel.username} followers=${manuel.followersCount} '
      'following=${manuel.followingCount} ratings=${ratings.length} likes=$likes';
}
