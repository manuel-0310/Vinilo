import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n.dart';
import '../util/search_text.dart';
import 'album.dart';
import 'follow.dart';
import 'rating.dart';

/// "Lista" normal o "Ranking" numerado (el orden importa).
enum ListKind {
  list('list'),
  ranking('ranking');

  const ListKind(this.key);

  final String key;

  /// "Lista" / "Ranking".
  String label(AppLocalizations l) => switch (this) {
        ListKind.list => l.listKindList,
        ListKind.ranking => l.listKindRanking,
      };

  static ListKind fromKey(String? key) =>
      key == ranking.key ? ranking : list;
}

/// De canciones o de discos, sin mezclar.
enum ListItemType {
  tracks('tracks'),
  albums('albums');

  const ListItemType(this.key);

  final String key;

  static ListItemType fromKey(String? key) =>
      key == albums.key ? albums : tracks;

  /// "Canciones" / "Discos".
  String label(AppLocalizations l) => switch (this) {
        ListItemType.tracks => l.listTypeTracks,
        ListItemType.albums => l.listTypeAlbums,
      };

  /// "3 canciones", "1 disco".
  String count(int n, AppLocalizations l) => switch (this) {
        ListItemType.tracks => l.countTracks(n),
        ListItemType.albums => l.countAlbums(n),
      };

  /// "Se agregaron 3 canciones".
  String added(int n, AppLocalizations l) => switch (this) {
        ListItemType.tracks => l.addedTracks(n),
        ListItemType.albums => l.addedAlbums(n),
      };

  /// "Agregar canciones" / "Agregar discos".
  String addLabel(AppLocalizations l) => switch (this) {
        ListItemType.tracks => l.listAddTracks,
        ListItemType.albums => l.listAddAlbums,
      };
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
  String typeLabel(AppLocalizations l) => switch ((kind, itemType)) {
        (ListKind.list, ListItemType.tracks) => l.listFullTypeTrackList,
        (ListKind.ranking, ListItemType.tracks) => l.listFullTypeTrackRanking,
        (ListKind.list, ListItemType.albums) => l.listFullTypeAlbumList,
        (ListKind.ranking, ListItemType.albums) => l.listFullTypeAlbumRanking,
      };

  /// Hasta cuatro portadas distintas, para las portadas apiladas.
  ///
  /// En las de canciones, las del mismo disco comparten portada, así que se
  /// toma una por disco y, si salen menos de 3, se repiten en orden hasta
  /// `min(3, canciones con portada)`: con 2 canciones o más siempre se ve la
  /// pila. Las de discos dan solo las distintas.
  List<String> get covers {
    final out = <String>[];
    final seen = <String>{};
    var withCover = 0;
    for (final i in items) {
      final c = i.smallCover;
      if (c == null) continue;
      withCover++;
      if (out.length < 4 && seen.add(i.albumId ?? c) && !out.contains(c)) out.add(c);
    }
    if (itemType == ListItemType.tracks && out.isNotEmpty) {
      final target = math.min(3, withCover);
      for (var k = 0; out.length < target; k++) {
        out.add(out[k]);
      }
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
  String message(ListItemType type, AppLocalizations l) {
    final parts = <String>[];
    if (added > 0) parts.add(type.added(added, l));
    if (duplicates > 0) {
      parts.add(added == 0 && duplicates == 1
          ? l.addAlreadyInList
          : l.addDuplicates(duplicates));
    }
    if (overflow > 0) parts.add(l.addOverflow(overflow, MusicList.maxItems));
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

/// Cómo se ordenan las listas del perfil.
enum ListSort { recent, name, size, likes }

/// El orden siguiente al tocar "recientes ↓" (vuelve al primero al final).
ListSort nextListSort(ListSort sort) =>
    ListSort.values[(sort.index + 1) % ListSort.values.length];

/// Los filtros de la pestaña Listas del perfil, en una sola fila y con una
/// opción a la vez: "Listas" y "Rankings" fijan el tipo, "Canciones" y
/// "Discos" el contenido, y "Todas" quita los dos.
enum ListFilter { all, lists, rankings, tracks, albums }

/// Búsqueda, filtros y orden de las listas del perfil. `kind` e `itemType`
/// null = todas.
class ListQuery {
  const ListQuery({
    this.text = '',
    this.kind,
    this.itemType,
    this.sort = ListSort.recent,
  });

  final String text;
  final ListKind? kind;
  final ListItemType? itemType;
  final ListSort sort;

  /// Hay algo que reduce el resultado (el orden no cuenta).
  bool get filtering => text.trim().isNotEmpty || kind != null || itemType != null;

  ListQuery copyWith({
    String? text,
    ListKind? Function()? kind,
    ListItemType? Function()? itemType,
    ListSort? sort,
  }) =>
      ListQuery(
        text: text ?? this.text,
        kind: kind == null ? this.kind : kind(),
        itemType: itemType == null ? this.itemType : itemType(),
        sort: sort ?? this.sort,
      );

  /// Quita búsqueda y filtros; conserva el orden.
  ListQuery cleared() => ListQuery(sort: sort);

  /// El filtro único que corresponde a esta consulta (si vienen tipo y
  /// contenido a la vez, manda el tipo).
  ListFilter get filter => switch (kind) {
        ListKind.list => ListFilter.lists,
        ListKind.ranking => ListFilter.rankings,
        null => switch (itemType) {
            ListItemType.tracks => ListFilter.tracks,
            ListItemType.albums => ListFilter.albums,
            null => ListFilter.all,
          },
      };

  /// La misma búsqueda y el mismo orden con otro filtro (solo uno a la vez).
  ListQuery withFilter(ListFilter filter) => ListQuery(
        text: text,
        sort: sort,
        kind: switch (filter) {
          ListFilter.lists => ListKind.list,
          ListFilter.rankings => ListKind.ranking,
          _ => null,
        },
        itemType: switch (filter) {
          ListFilter.tracks => ListItemType.tracks,
          ListFilter.albums => ListItemType.albums,
          _ => null,
        },
      );
}

/// Si la lista coincide con el texto: por su nombre, su descripción o el
/// nombre y artista de lo que tiene dentro ("la lista que tiene Kid A").
bool listMatches(MusicList list, String text) {
  final q = foldForSearch(text);
  if (q.isEmpty) return true;
  bool has(String s) => foldForSearch(s).contains(q);
  return has(list.name) ||
      has(list.description) ||
      list.items.any((i) => has(i.name) || has(i.artist));
}

/// Aplica búsqueda, filtros y orden. No modifica la lista original.
List<MusicList> applyListQuery(List<MusicList> lists, ListQuery query) {
  final out = lists.where((l) {
    if (query.kind != null && l.kind != query.kind) return false;
    if (query.itemType != null && l.itemType != query.itemType) return false;
    return listMatches(l, query.text);
  }).toList();
  int byRecent(MusicList a, MusicList b) => b.updatedAt.compareTo(a.updatedAt);
  out.sort(switch (query.sort) {
    ListSort.recent => byRecent,
    ListSort.name => (a, b) => foldForSearch(a.name).compareTo(foldForSearch(b.name)),
    ListSort.size => (a, b) {
        final c = b.count.compareTo(a.count);
        return c != 0 ? c : byRecent(a, b);
      },
    ListSort.likes => (a, b) {
        final c = b.likes.compareTo(a.likes);
        return c != 0 ? c : byRecent(a, b);
      },
  });
  return out;
}
