import '../l10n/l10n.dart';
import '../theme/score.dart';
import 'affinity.dart';
import 'follow.dart';
import 'rating.dart';

/// El periodo de las estadísticas: "Este mes", "Este año" o "Siempre".
enum StatsPeriod {
  month,
  year,
  all;

  String label(AppLocalizations l) => switch (this) {
        StatsPeriod.month => l.statsPeriodMonth,
        StatsPeriod.year => l.statsPeriodYear,
        StatsPeriod.all => l.statsPeriodAll,
      };

  /// Desde cuándo cuenta (null = siempre).
  DateTime? start(DateTime now) => switch (this) {
        StatsPeriod.month => DateTime(now.year, now.month),
        StatsPeriod.year => DateTime(now.year),
        StatsPeriod.all => null,
      };
}

/// Las notas que entran en el periodo, por la fecha en que se pusieron.
List<RatingEntry> ratingsIn(Iterable<RatingEntry> all, StatsPeriod period, DateTime now) {
  final since = period.start(now);
  return [
    for (final r in all)
      if (since == null || !r.createdAt.isBefore(since)) r,
  ];
}

/// Un artista del top: cuántos discos suyos califiqué y con qué promedio.
class ArtistStat {
  const ArtistStat({
    required this.id,
    required this.name,
    required this.count,
    required this.average,
  });

  /// Id de Spotify (vacío en notas viejas que solo guardan el nombre).
  final String id;
  final String name;
  final int count;
  final double average;
}

/// Una década y cuántos discos suyos califiqué.
class DecadeStat {
  const DecadeStat({required this.decade, required this.count});

  /// El primer año de la década (1990, 2000…).
  final int decade;
  final int count;

  /// "90s", "00s".
  String get label => '${(decade % 100).toString().padLeft(2, '0')}s';
}

/// Una porción de una barra apilada (un género o un país) con su cuenta.
class ShareStat {
  const ShareStat({required this.key, required this.count, required this.percent});

  /// El género o el código del país; vacío para "Otros".
  final String key;
  final int count;

  /// Porcentaje redondeado sobre el total.
  final int percent;
}

/// País y géneros de un artista (`artistMeta/{id}`).
class ArtistMeta {
  const ArtistMeta({this.country, this.genres = const []});

  /// Código ISO de dos letras ("AR"), o null si no se sabe.
  final String? country;

  /// Del más al menos representativo.
  final List<String> genres;

  factory ArtistMeta.fromMap(Map<String, dynamic> m) {
    final country = (m['country'] as String?)?.trim().toUpperCase();
    return ArtistMeta(
      country: country == null || country.isEmpty ? null : country,
      genres: [
        for (final g in (m['genres'] as List?) ?? const [])
          if (g is String && g.trim().isNotEmpty) g.trim().toLowerCase(),
      ],
    );
  }
}

/// Todo lo que la pestaña Estadísticas calcula solo con mis notas.
class ProfileStats {
  const ProfileStats({
    required this.total,
    required this.average,
    required this.hist,
    required this.mode,
    required this.artists,
    required this.decades,
    required this.months,
    required this.year,
    required this.streakWeeks,
    required this.durationMs,
    required this.withDuration,
  });

  /// Discos calificados en el periodo.
  final int total;

  /// Mi nota promedio (null sin notas).
  final double? average;

  /// Cuántos discos con cada nota (claves 1 a 10).
  final Map<int, int> hist;

  /// Mi nota más común (la más baja si hay empate; null sin notas).
  final int? mode;

  /// Los 5 artistas con más discos calificados.
  final List<ArtistStat> artists;

  /// Las décadas con algún disco, de la más antigua a la más nueva.
  final List<DecadeStat> decades;

  /// Discos por mes del año en curso (12 valores, enero primero). No
  /// depende del periodo: es "Tu ritmo".
  final List<int> months;
  final int year;

  /// Semanas seguidas calificando al menos un disco, hasta esta.
  final int streakWeeks;

  /// Suma de la duración de los discos del periodo que la tienen guardada,
  /// y cuántos son.
  final int durationMs;
  final int withDuration;

  /// La década con más discos (la más reciente si hay empate).
  DecadeStat? get mainDecade {
    DecadeStat? best;
    for (final d in decades) {
      if (best == null || d.count >= best.count) best = d;
    }
    return best;
  }

  /// A cuántos discos del periodo les falta la duración.
  int get missingDuration => total - withDuration;

  int get hours => (durationMs / Duration.millisecondsPerHour).round();
}

/// Cuántos artistas se muestran en "Artistas que más escuchas".
const int statsTopArtists = 5;

/// El lunes de la semana de `date`, a medianoche.
DateTime weekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - DateTime.monday));

/// Semanas seguidas con al menos una nota, contando hacia atrás desde esta.
/// Si esta semana todavía no hay ninguna, la racha sigue viva si la hubo la
/// semana pasada.
int streakWeeks(Iterable<RatingEntry> ratings, DateTime now) {
  final weeks = {for (final r in ratings) weekStart(r.createdAt)};
  var week = weekStart(now);
  if (!weeks.contains(week)) {
    week = DateTime(week.year, week.month, week.day - 7);
  }
  var streak = 0;
  while (weeks.contains(week)) {
    streak++;
    week = DateTime(week.year, week.month, week.day - 7);
  }
  return streak;
}

/// Las estadísticas de `all` (todas mis notas) para un periodo.
ProfileStats computeStats(
  Iterable<RatingEntry> all, {
  required StatsPeriod period,
  required DateTime now,
}) {
  final everything = all.toList();
  final ratings = ratingsIn(everything, period, now);

  final hist = {for (var i = 1; i <= 10; i++) i: 0};
  var sum = 0;
  var durationMs = 0;
  var withDuration = 0;
  final byArtist = <String, ({String id, String name, int count, int sum})>{};
  final byDecade = <int, int>{};
  for (final r in ratings) {
    sum += r.score;
    if (hist.containsKey(r.score)) hist[r.score] = hist[r.score]! + 1;
    final duration = r.album.durationMs;
    if (duration != null && duration > 0) {
      durationMs += duration;
      withDuration++;
    }
    final year = r.album.year;
    if (year != null && year > 0) {
      final decade = year ~/ 10 * 10;
      byDecade[decade] = (byDecade[decade] ?? 0) + 1;
    }
    // Cada artista del disco cuenta; las notas viejas solo traen el nombre.
    final artists = r.album.artists.where((a) => a.name.isNotEmpty).toList();
    final names = artists.isEmpty
        ? [if (r.album.artist.isNotEmpty) (id: '', name: r.album.artist)]
        : [for (final a in artists) (id: a.id, name: a.name)];
    for (final a in names) {
      final key = a.id.isEmpty ? 'name:${a.name.toLowerCase()}' : a.id;
      final prev = byArtist[key];
      byArtist[key] = (
        id: a.id,
        name: a.name,
        count: (prev?.count ?? 0) + 1,
        sum: (prev?.sum ?? 0) + r.score,
      );
    }
  }

  int? mode;
  var most = 0;
  for (var i = 1; i <= 10; i++) {
    if (hist[i]! > most) {
      most = hist[i]!;
      mode = i;
    }
  }

  final artists = [
    for (final a in byArtist.values)
      ArtistStat(id: a.id, name: a.name, count: a.count, average: a.sum / a.count),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final byAverage = b.average.compareTo(a.average);
      return byAverage != 0 ? byAverage : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  final decades = [
    for (final d in byDecade.keys.toList()..sort()) DecadeStat(decade: d, count: byDecade[d]!),
  ];

  final months = List<int>.filled(12, 0);
  for (final r in everything) {
    if (r.createdAt.year == now.year) months[r.createdAt.month - 1]++;
  }

  return ProfileStats(
    total: ratings.length,
    average: ratings.isEmpty ? null : sum / ratings.length,
    hist: hist,
    mode: mode,
    artists: artists.take(statsTopArtists).toList(),
    decades: decades,
    months: months,
    year: now.year,
    streakWeeks: streakWeeks(everything, now),
    durationMs: durationMs,
    withDuration: withDuration,
  );
}

/// Mi promedio y el de los demás en los mismos discos. Solo cuentan los
/// discos que alguien más calificó, y de su promedio se quita mi nota. Null
/// si no hay ninguno.
({double mine, double community, int albums})? communityComparison(
  Iterable<RatingEntry> ratings,
  Map<String, AlbumStats> stats,
) {
  var mine = 0.0;
  var community = 0.0;
  var albums = 0;
  for (final r in ratings) {
    final s = stats[r.albumId];
    if (s == null) continue;
    final others = s.count - 1;
    if (others <= 0) continue;
    mine += r.score;
    community += (s.sum - r.score) / others;
    albums++;
  }
  if (albums == 0) return null;
  return (mine: mine / albums, community: community / albums, albums: albums);
}

/// Una frase con un trozo en énfasis: en los ARB ese trozo va entre
/// asteriscos ("Calificas *0,5 puntos más alto* que la comunidad."), así
/// cada idioma lo coloca donde le toca.
({String before, String accent, String after}) accentParts(String sentence) {
  final first = sentence.indexOf('*');
  final last = sentence.lastIndexOf('*');
  if (first < 0 || last <= first) return (before: sentence, accent: '', after: '');
  return (
    before: sentence.substring(0, first),
    accent: sentence.substring(first + 1, last),
    after: sentence.substring(last + 1),
  );
}

/// "Calificas 0,5 puntos más alto que la comunidad. Su promedio en los
/// mismos discos es 6,9." Con menos de 0,05 de diferencia, "igual".
({String before, String accent, String after}) comparisonSentence(
  ({double mine, double community, int albums}) c,
  AppLocalizations l,
) {
  final diff = c.mine - c.community;
  final amount = Score.formatAverage(diff.abs(), l.localeName);
  final average = Score.formatAverage(c.community, l.localeName);
  return accentParts(
    diff.abs() < 0.05
        ? l.statsCompareSame(average)
        : diff > 0
            ? l.statsCompareHigher(amount, average)
            : l.statsCompareLower(amount, average),
  );
}

/// La afinidad con una persona a la que sigo.
class FriendAffinity {
  const FriendAffinity({
    required this.person,
    required this.percent,
    required this.common,
    required this.albums,
  });

  final PersonInfo person;
  final int percent;
  final int common;
  final List<CommonAlbum> albums;
}

/// De las personas que sigo, la más afín y la menos afín (solo cuentan las
/// que tienen discos en común conmigo). Con una sola, solo hay "más afín".
({FriendAffinity? most, FriendAffinity? least}) friendExtremes(
  Iterable<RatingEntry> mine,
  Map<String, List<RatingEntry>> theirs,
  Iterable<PersonInfo> people,
) {
  final mineList = mine.toList();
  final all = <FriendAffinity>[];
  for (final person in people) {
    final result = affinityBetween(mineList, theirs[person.uid] ?? const []);
    final percent = result.percent;
    if (percent == null) continue;
    all.add(
      FriendAffinity(
        person: person,
        percent: percent,
        common: result.common,
        albums: result.albums,
      ),
    );
  }
  if (all.isEmpty) return (most: null, least: null);
  FriendAffinity most = all.first;
  FriendAffinity least = all.first;
  for (final f in all.skip(1)) {
    if (f.percent > most.percent || (f.percent == most.percent && f.common > most.common)) {
      most = f;
    }
    if (f.percent < least.percent || (f.percent == least.percent && f.common > least.common)) {
      least = f;
    }
  }
  return (most: most, least: identical(most, least) ? null : least);
}

/// Cuántas porciones propias lleva la barra de géneros antes de "Otros".
const int statsTopGenres = 4;

/// Los géneros de mis discos: el género principal del primer artista de
/// cada disco. Los [statsTopGenres] con más discos y, si sobra, "Otros"
/// (con `key` vacío). Vacío si de ningún disco se sabe el género.
List<ShareStat> genreShares(Iterable<RatingEntry> ratings, Map<String, ArtistMeta> meta) {
  final counts = <String, int>{};
  for (final r in ratings) {
    final genre = _firstMeta(r, meta)?.genres.firstOrNull;
    if (genre == null) continue;
    counts[genre] = (counts[genre] ?? 0) + 1;
  }
  final total = counts.values.fold<int>(0, (s, n) => s + n);
  if (total == 0) return const [];
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  final top = sorted.take(statsTopGenres).toList();
  final rest = sorted.skip(statsTopGenres).fold<int>(0, (s, e) => s + e.value);
  int percent(int n) => (n / total * 100).round();
  return [
    for (final e in top) ShareStat(key: e.key, count: e.value, percent: percent(e.value)),
    if (rest > 0) ShareStat(key: '', count: rest, percent: percent(rest)),
  ];
}

/// De dónde vienen mis discos: el país del primer artista de cada uno, de
/// más a menos discos. `countries` es cuántos países distintos hay; `top`,
/// los cinco primeros.
({int countries, List<ShareStat> top}) countryShares(
  Iterable<RatingEntry> ratings,
  Map<String, ArtistMeta> meta, {
  int limit = 5,
}) {
  final counts = <String, int>{};
  for (final r in ratings) {
    final country = _firstMeta(r, meta)?.country;
    if (country == null) continue;
    counts[country] = (counts[country] ?? 0) + 1;
  }
  final total = counts.values.fold<int>(0, (s, n) => s + n);
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return (
    countries: counts.length,
    top: [
      for (final e in sorted.take(limit))
        ShareStat(key: e.key, count: e.value, percent: (e.value / total * 100).round()),
    ],
  );
}

ArtistMeta? _firstMeta(RatingEntry r, Map<String, ArtistMeta> meta) {
  for (final id in r.album.artistIds) {
    final m = meta[id];
    if (m != null) return m;
  }
  return null;
}

/// La línea bajo las horas de "Tiempo escuchando": con un día o más, "≈ 1,7
/// días seguidos"; con menos, "≈ 8 discos".
String listeningEquivalent(ProfileStats stats, AppLocalizations l) {
  final hours = stats.durationMs / Duration.millisecondsPerHour;
  if (hours < 24) return l.statsTimeAlbums(stats.withDuration);
  final days = hours / 24;
  final rounded = (days * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : Score.formatAverage(rounded, l.localeName);
  return l.statsTimeDays(text);
}
