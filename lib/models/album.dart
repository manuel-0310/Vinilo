/// Álbum tal como lo devuelve la Cloud Function (normalizado) o como se
/// guarda de forma compacta dentro de Firestore.
class Album {
  const Album({
    required this.id,
    required this.name,
    required this.artist,
    this.artistIds = const [],
    this.year,
    this.releaseDate,
    this.type,
    this.totalTracks,
    this.cover,
    this.coverSmall,
    this.coverThumb,
    this.spotifyUrl,
  });

  final String id;
  final String name;
  final String artist;
  final List<String> artistIds;
  final int? year;
  final String? releaseDate;
  final String? type;
  final int? totalTracks;
  final String? cover;
  final String? coverSmall;
  final String? coverThumb;
  final String? spotifyUrl;

  factory Album.fromJson(Map<String, dynamic> j) {
    final artists = (j['artists'] as List?) ?? const [];
    return Album(
      id: j['id'] as String,
      name: (j['name'] ?? '') as String,
      artist: (j['artist'] ?? '') as String,
      artistIds: artists
          .map((a) => ((a as Map)['id'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .toList(),
      year: (j['year'] as num?)?.toInt(),
      releaseDate: j['releaseDate'] as String?,
      type: j['type'] as String?,
      totalTracks: (j['totalTracks'] as num?)?.toInt(),
      cover: j['cover'] as String?,
      coverSmall: j['coverSmall'] as String?,
      coverThumb: j['coverThumb'] as String?,
      spotifyUrl: j['spotifyUrl'] as String?,
    );
  }

  factory Album.fromMap(Map<String, dynamic> m) {
    return Album(
      id: (m['id'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      artist: (m['artist'] ?? '') as String,
      artistIds: List<String>.from((m['artistIds'] as List?) ?? const []),
      year: (m['year'] as num?)?.toInt(),
      type: m['type'] as String?,
      totalTracks: (m['totalTracks'] as num?)?.toInt(),
      cover: m['cover'] as String?,
      coverSmall: m['coverSmall'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'artist': artist,
        'artistIds': artistIds,
        'year': year,
        'type': type,
        'totalTracks': totalTracks,
        'cover': cover,
        'coverSmall': coverSmall,
      };

  String? get bestCover => cover ?? coverSmall ?? coverThumb;
  String? get smallCover => coverSmall ?? cover ?? coverThumb;

  String get typeLabel => switch (type) {
        'single' => 'Sencillo',
        'compilation' => 'Recopilatorio',
        _ => 'Álbum',
      };

  String get subtitle => [artist, if (year != null) '$year'].join(' · ');

  String get meta => [
        if (year != null) '$year',
        typeLabel,
        if (totalTracks != null)
          '$totalTracks ${totalTracks == 1 ? 'canción' : 'canciones'}',
      ].join(' · ');
}

class Track {
  const Track({
    required this.id,
    required this.name,
    required this.number,
    required this.disc,
    required this.durationMs,
    required this.explicit,
    required this.artists,
  });

  final String id;
  final String name;
  final int number;
  final int disc;
  final int durationMs;
  final bool explicit;
  final String artists;

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        number: (j['number'] as num?)?.toInt() ?? 0,
        disc: (j['disc'] as num?)?.toInt() ?? 1,
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        explicit: j['explicit'] == true,
        artists: (j['artists'] ?? '') as String,
      );

  String get duration {
    final total = durationMs ~/ 1000;
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class AlbumDetail extends Album {
  const AlbumDetail({
    required super.id,
    required super.name,
    required super.artist,
    super.artistIds,
    super.year,
    super.releaseDate,
    super.type,
    super.totalTracks,
    super.cover,
    super.coverSmall,
    super.coverThumb,
    super.spotifyUrl,
    this.label,
    this.popularity,
    this.genres = const [],
    this.copyright,
    this.tracks = const [],
  });

  final String? label;
  final int? popularity;
  final List<String> genres;
  final String? copyright;
  final List<Track> tracks;

  factory AlbumDetail.fromJson(Map<String, dynamic> j) {
    final base = Album.fromJson(j);
    return AlbumDetail(
      id: base.id,
      name: base.name,
      artist: base.artist,
      artistIds: base.artistIds,
      year: base.year,
      releaseDate: base.releaseDate,
      type: base.type,
      totalTracks: base.totalTracks,
      cover: base.cover,
      coverSmall: base.coverSmall,
      coverThumb: base.coverThumb,
      spotifyUrl: base.spotifyUrl,
      label: j['label'] as String?,
      popularity: (j['popularity'] as num?)?.toInt(),
      genres: List<String>.from((j['genres'] as List?) ?? const []),
      copyright: j['copyright'] as String?,
      tracks: ((j['tracks'] as List?) ?? const [])
          .map((t) => Track.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList(),
    );
  }

  Duration get totalDuration =>
      Duration(milliseconds: tracks.fold(0, (sum, t) => sum + t.durationMs));

  String get totalDurationLabel {
    final d = totalDuration;
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return '${d.inHours} h ${d.inMinutes % 60} min';
  }
}

class AlbumPage {
  const AlbumPage({required this.items, required this.total, this.nextOffset});

  final List<Album> items;
  final int total;
  final int? nextOffset;

  factory AlbumPage.fromJson(Map<String, dynamic> j) => AlbumPage(
        items: ((j['items'] as List?) ?? const [])
            .map((a) => Album.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
        total: (j['total'] as num?)?.toInt() ?? 0,
        nextOffset: (j['nextOffset'] as num?)?.toInt(),
      );

  AlbumPage merge(AlbumPage next) => AlbumPage(
        items: [...items, ...next.items],
        total: next.total,
        nextOffset: next.nextOffset,
      );
}
