import 'package:cloud_firestore/cloud_firestore.dart';

import 'album.dart';
import 'follow.dart';
import 'rating.dart';

/// "Lista" normal o "Ranking" numerado (el orden importa).
enum ListKind {
  list('list', 'Lista'),
  ranking('ranking', 'Ranking');

  const ListKind(this.key, this.label);

  final String key;
  final String label;

  static ListKind fromKey(String? key) =>
      key == ranking.key ? ranking : list;
}

/// De canciones o de discos, sin mezclar.
enum ListItemType {
  tracks('tracks', 'Canciones', 'canción', 'canciones'),
  albums('albums', 'Discos', 'disco', 'discos');

  const ListItemType(this.key, this.label, this.one, this.many);

  final String key;
  final String label;
  final String one;
  final String many;

  static ListItemType fromKey(String? key) =>
      key == albums.key ? albums : tracks;

  String count(int n) => '$n ${n == 1 ? one : many}';
}

/// Un elemento copiado dentro de la lista (id de Spotify, nombre, artista,
/// portada y, según el tipo, disco y duración o año): así la lista se abre
/// sin llamar a Spotify.
class ListItem {
  const ListItem({
    required this.id,
    required this.name,
    required this.artist,
    this.cover,
    this.coverSmall,
    this.albumId,
    this.albumName,
    this.durationMs,
    this.year,
    this.artistIds = const [],
    this.artistNames = const [],
  });

  final String id;
  final String name;
  final String artist;
  final String? cover;
  final String? coverSmall;

  /// Canciones: el disco al que pertenecen.
  final String? albumId;
  final String? albumName;
  final int? durationMs;

  /// Discos: el año.
  final int? year;
  final List<String> artistIds;
  final List<String> artistNames;

  bool get isTrack => albumId != null;

  String? get smallCover => coverSmall ?? cover;

  /// "3:42" para canciones, "2016" para discos.
  String get meta {
    final ms = durationMs;
    if (ms != null) {
      final total = ms ~/ 1000;
      return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
    }
    return year == null ? '' : '$year';
  }

  /// "Artista · Disco" para canciones, "Artista" para discos.
  String get subtitle => [
        artist,
        if (isTrack && albumName != null && albumName!.isNotEmpty) albumName!,
      ].join(' · ');

  /// El disco que abre este elemento (el suyo o el que lo contiene).
  Album get album => Album(
        id: albumId ?? id,
        name: albumName ?? name,
        artist: artist,
        artistIds: artistIds,
        artistNames: artistNames,
        year: year,
        cover: cover,
        coverSmall: coverSmall,
      );

  factory ListItem.fromTrack(Track track, Album album) => ListItem(
        id: track.id,
        name: track.name,
        artist: track.artists.isEmpty ? album.artist : track.artists,
        cover: album.cover,
        coverSmall: album.coverSmall,
        albumId: album.id,
        albumName: album.name,
        durationMs: track.durationMs,
        artistIds: album.artistIds,
        artistNames: album.artistNames,
      );

  factory ListItem.fromAlbum(Album album) => ListItem(
        id: album.id,
        name: album.name,
        artist: album.artist,
        cover: album.cover,
        coverSmall: album.coverSmall,
        year: album.year,
        artistIds: album.artistIds,
        artistNames: album.artistNames,
      );

  factory ListItem.fromMap(Map<String, dynamic> m) => ListItem(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        artist: (m['artist'] ?? '') as String,
        cover: m['cover'] as String?,
        coverSmall: m['coverSmall'] as String?,
        albumId: m['albumId'] as String?,
        albumName: m['albumName'] as String?,
        durationMs: (m['durationMs'] as num?)?.toInt(),
        year: (m['year'] as num?)?.toInt(),
        artistIds: List<String>.from((m['artistIds'] as List?) ?? const []),
        artistNames: List<String>.from((m['artistNames'] as List?) ?? const []),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'artist': artist,
        'cover': cover,
        'coverSmall': coverSmall,
        if (albumId != null) 'albumId': albumId,
        if (albumName != null) 'albumName': albumName,
        if (durationMs != null) 'durationMs': durationMs,
        if (year != null) 'year': year,
        if (artistIds.isNotEmpty) 'artistIds': artistIds,
        if (artistNames.isNotEmpty) 'artistNames': artistNames,
      };
}

/// Una lista o ranking en `lists/{id}`, con sus elementos dentro.
class MusicList {
  const MusicList({
    required this.id,
    required this.ownerUid,
    required this.owner,
    required this.name,
    required this.description,
    required this.kind,
    required this.itemType,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.likedBy = const [],
    this.savedBy = const [],
    this.coverUrl,
    this.coverPath,
  });

  /// Tope de elementos por lista: caben de sobra en un documento (≈ 100 KB).
  static const int maxItems = 300;
  static const int maxNameLength = 60;
  static const int maxDescriptionLength = 300;

  final String id;
  final String ownerUid;
  final PersonInfo owner;
  final String name;
  final String description;
  final ListKind kind;
  final ListItemType itemType;
  final List<ListItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likedBy;
  final List<String> savedBy;

  /// Portada elegida por su autora (Storage `lists/{id}/{marca}.jpg`). Null:
  /// se muestra el mosaico con las portadas de los elementos.
  final String? coverUrl;

  /// Ruta en Storage de la portada, para borrarla al cambiarla o al borrar
  /// la lista.
  final String? coverPath;

  int get count => items.length;
  int get likes => likedBy.length;
  bool get isRanking => kind == ListKind.ranking;
  bool likedByMe(String uid) => likedBy.contains(uid);
  bool savedByMe(String uid) => savedBy.contains(uid);
  bool isMine(String uid) => ownerUid == uid;
  bool containsId(String id) => items.any((i) => i.id == id);

  /// "Ranking de canciones", "Lista de discos".
  String get typeLabel => '${kind.label} de ${itemType.label.toLowerCase()}';

  /// Hasta cuatro portadas distintas para el mosaico.
  List<String> get covers {
    final out = <String>[];
    for (final i in items) {
      final c = i.smallCover;
      if (c != null && !out.contains(c)) out.add(c);
      if (out.length == 4) break;
    }
    return out;
  }

  factory MusicList.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ownerUid = (d['ownerUid'] ?? '') as String;
    return MusicList(
      id: doc.id,
      ownerUid: ownerUid,
      owner: PersonInfo.fromMap(
        ownerUid,
        Map<String, dynamic>.from((d['owner'] as Map?) ?? {}),
      ),
      name: (d['name'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      kind: ListKind.fromKey(d['kind'] as String?),
      itemType: ListItemType.fromKey(d['itemType'] as String?),
      items: ((d['items'] as List?) ?? const [])
          .map((m) => ListItem.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      createdAt: dateFrom(d['createdAt']),
      updatedAt: dateFrom(d['updatedAt']),
      likedBy: List<String>.from((d['likedBy'] as List?) ?? const []),
      savedBy: List<String>.from((d['savedBy'] as List?) ?? const []),
      coverUrl: d['coverUrl'] as String?,
      coverPath: d['coverPath'] as String?,
    );
  }

  MusicList copyWith({
    String? name,
    String? description,
    List<ListItem>? items,
  }) =>
      MusicList(
        id: id,
        ownerUid: ownerUid,
        owner: owner,
        name: name ?? this.name,
        description: description ?? this.description,
        kind: kind,
        itemType: itemType,
        items: items ?? this.items,
        createdAt: createdAt,
        updatedAt: updatedAt,
        likedBy: likedBy,
        savedBy: savedBy,
        coverUrl: coverUrl,
        coverPath: coverPath,
      );
}

/// Qué pasó al agregar: la lista resultante, cuántos entraron, cuántos ya
/// estaban y cuántos no cupieron por el tope.
class AddOutcome {
  const AddOutcome({
    required this.items,
    required this.added,
    required this.duplicates,
    required this.overflow,
  });

  final List<ListItem> items;
  final int added;
  final int duplicates;
  final int overflow;

  bool get nothingAdded => added == 0;

  /// Mensaje corto para la persona ("Se agregaron 3 canciones", "Ya
  /// estaba en la lista"…).
  String message(ListItemType type) {
    final parts = <String>[];
    if (added > 0) {
      parts.add(added == 1
          ? 'Se agregó 1 ${type.one}'
          : 'Se agregaron ${type.count(added)}');
    }
    if (duplicates > 0) {
      parts.add(added == 0 && duplicates == 1
          ? 'Ya estaba en la lista'
          : duplicates == 1
              ? '1 ya estaba'
              : '$duplicates ya estaban');
    }
    if (overflow > 0) {
      parts.add(overflow == 1
          ? '1 no cupo (tope de ${MusicList.maxItems})'
          : '$overflow no cupieron (tope de ${MusicList.maxItems})');
    }
    return parts.join(' · ');
  }
}

/// Agrega `incoming` al final de `current` sin repetir ids (ni los que ya
/// estaban ni los repetidos dentro de `incoming`), respetando el tope.
AddOutcome addItems(
  List<ListItem> current,
  Iterable<ListItem> incoming, {
  int max = MusicList.maxItems,
}) {
  final ids = {for (final i in current) i.id};
  final out = [...current];
  var added = 0;
  var duplicates = 0;
  var overflow = 0;
  for (final item in incoming) {
    if (ids.contains(item.id)) {
      duplicates++;
      continue;
    }
    if (out.length >= max) {
      overflow++;
      continue;
    }
    ids.add(item.id);
    out.add(item);
    added++;
  }
  return AddOutcome(
    items: out,
    added: added,
    duplicates: duplicates,
    overflow: overflow,
  );
}

/// Mueve el elemento de `oldIndex` a `newIndex` con la convención de
/// `ReorderableListView`: al arrastrar hacia abajo, `newIndex` viene
/// contado sobre la lista original (uno de más).
List<T> reorder<T>(List<T> items, int oldIndex, int newIndex) {
  final out = [...items];
  if (oldIndex < 0 || oldIndex >= out.length) return out;
  var target = newIndex;
  if (target > oldIndex) target -= 1;
  target = target.clamp(0, out.length - 1);
  if (target == oldIndex) return out;
  final item = out.removeAt(oldIndex);
  out.insert(target, item);
  return out;
}

List<ListItem> removeItem(List<ListItem> items, String id) =>
    items.where((i) => i.id != id).toList();

/// Devuelve `item` a la posición `index` (para "Deshacer" al quitar). Si ya
/// está en la lista no hace nada, y si la lista cambió mientras tanto, la
/// posición se ajusta a los límites.
List<ListItem> insertItemAt(List<ListItem> items, ListItem item, int index) {
  if (items.any((i) => i.id == item.id)) return [...items];
  final out = [...items];
  out.insert(index.clamp(0, out.length), item);
  return out;
}
