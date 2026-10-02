import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/stats.dart';
import 'package:no_retiene/screens/profile_stats_tab.dart';
import 'package:no_retiene/screens/share_stats_screen.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

RatingEntry _r(
  String album,
  int score, {
  required DateTime at,
  String uid = 'me',
  int? year,
  List<(String, String)> artists = const [('ar1', 'Gustavo Cerati')],
  int? durationMs,
}) =>
    RatingEntry(
      id: RatingEntry.docId(uid, album),
      uid: uid,
      albumId: album,
      score: score,
      note: '',
      createdAt: at,
      updatedAt: at,
      album: Album(
        id: album,
        name: 'Disco $album',
        artist: artists.map((a) => a.$2).join(', '),
        artistIds: [for (final a in artists) a.$1],
        artistNames: [for (final a in artists) a.$2],
        year: year,
        durationMs: durationMs,
      ),
      user: RaterInfo(uid: uid, name: uid, colorValue: 0xFF000000),
    );

AlbumStats _stats(String id, {required int count, required int sum}) => AlbumStats(
      album: Album(id: id, name: id, artist: 'x'),
      count: count,
      sum: sum,
      hist: const {},
    );

final _es = lookupAppLocalizations(const Locale('es'));
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  // Jueves 2 de octubre de 2026.
  final now = DateTime(2026, 10, 2, 15);

  group('periodos', () {
    final all = [
      _r('a', 8, at: DateTime(2026, 10, 1)),
      _r('b', 7, at: DateTime(2026, 3, 10)),
      _r('c', 9, at: DateTime(2025, 12, 31)),
    ];

    test('este mes, este año y siempre', () {
      expect(ratingsIn(all, StatsPeriod.month, now).map((r) => r.albumId), ['a']);
      expect(ratingsIn(all, StatsPeriod.year, now).map((r) => r.albumId), ['a', 'b']);
      expect(ratingsIn(all, StatsPeriod.all, now), hasLength(3));
    });

    test('los nombres de los periodos, como en el prototipo', () {
      expect([for (final p in StatsPeriod.values) p.label(_es)], ['Este mes', 'Este año', 'Siempre']);
      expect([for (final p in StatsPeriod.values) p.label(_en)], ['This month', 'This year', 'All time']);
    });
  });

  group('computeStats', () {
    final all = [
      _r('a', 8, at: DateTime(2026, 9, 28), year: 1999, durationMs: 3600000),
      _r('b', 8, at: DateTime(2026, 9, 20), year: 1995, durationMs: 1800000),
      _r('c', 10, at: DateTime(2026, 7, 4), year: 2009, artists: const [('ar2', 'Radiohead')]),
      _r('d', 6, at: DateTime(2026, 2, 1), year: 2022, artists: const [('ar2', 'Radiohead'), ('ar3', 'Thom Yorke')]),
      _r('e', 5, at: DateTime(2024, 5, 1), year: 1975, artists: const [('ar4', 'Pink Floyd')]),
    ];

    test('resumen, histograma y nota más común del año', () {
      final s = computeStats(all, period: StatsPeriod.year, now: now);
      expect(s.total, 4);
      expect(s.average, closeTo(8.0, 1e-9));
      expect(s.hist[8], 2);
      expect(s.hist[10], 1);
      expect(s.hist[5], 0);
      expect(s.mode, 8);
    });

    test('con empate, la nota más común es la más baja (como el prototipo)', () {
      final s = computeStats([
        _r('a', 9, at: DateTime(2026, 9, 1)),
        _r('b', 6, at: DateTime(2026, 9, 2)),
      ], period: StatsPeriod.all, now: now);
      expect(s.mode, 6);
    });

    test('artistas: cuentan todos los del disco, de más discos a menos', () {
      final s = computeStats(all, period: StatsPeriod.all, now: now);
      expect(s.artists.map((a) => a.name).take(2), ['Gustavo Cerati', 'Radiohead']);
      final radiohead = s.artists.firstWhere((a) => a.name == 'Radiohead');
      expect(radiohead.count, 2);
      expect(radiohead.average, 8);
      expect(s.artists.any((a) => a.name == 'Thom Yorke'), isTrue);
      expect(s.artists.length, lessThanOrEqualTo(statsTopArtists));
    });

    test('décadas en orden, con su etiqueta y la principal', () {
      final s = computeStats(all, period: StatsPeriod.all, now: now);
      expect([for (final d in s.decades) d.label], ['70s', '90s', '00s', '20s']);
      expect(s.mainDecade?.label, '90s');
    });

    test('a igual cuenta, la década principal es la más reciente', () {
      final s = computeStats([
        _r('a', 7, at: DateTime(2026, 1, 1), year: 1991),
        _r('b', 7, at: DateTime(2026, 1, 2), year: 2011),
      ], period: StatsPeriod.all, now: now);
      expect(s.mainDecade?.label, '10s');
    });

    test('el ritmo es siempre del año en curso, sea cual sea el periodo', () {
      final month = computeStats(all, period: StatsPeriod.month, now: now);
      expect(month.year, 2026);
      expect(month.months, [0, 1, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0]);
    });

    test('tiempo: solo suma los discos con duración y cuenta los que faltan', () {
      final s = computeStats(all, period: StatsPeriod.year, now: now);
      expect(s.durationMs, 5400000);
      expect(s.withDuration, 2);
      expect(s.missingDuration, 2);
      expect(s.hours, 2);
    });

    test('sin notas en el periodo', () {
      final s = computeStats(all, period: StatsPeriod.month, now: DateTime(2026, 11, 3));
      expect(s.total, 0);
      expect(s.average, isNull);
      expect(s.mode, isNull);
      expect(s.artists, isEmpty);
    });
  });

  group('racha', () {
    test('cuenta semanas seguidas hasta esta', () {
      final ratings = [
        _r('a', 8, at: DateTime(2026, 10, 1)), // esta semana (lunes 28 sep)
        _r('b', 8, at: DateTime(2026, 9, 22)), // la anterior
        _r('c', 8, at: DateTime(2026, 9, 14)), // la de antes
        _r('d', 8, at: DateTime(2026, 8, 30)), // con un hueco: no cuenta
      ];
      expect(streakWeeks(ratings, now), 3);
    });

    test('si esta semana aún no hay notas, sigue viva por la pasada', () {
      expect(streakWeeks([_r('a', 8, at: DateTime(2026, 9, 25))], now), 1);
    });

    test('sin notas recientes no hay racha', () {
      expect(streakWeeks([_r('a', 8, at: DateTime(2026, 9, 1))], now), 0);
      expect(streakWeeks(const [], now), 0);
    });

    test('la semana empieza el lunes', () {
      expect(weekStart(DateTime(2026, 10, 2, 23)), DateTime(2026, 9, 28));
      expect(weekStart(DateTime(2026, 9, 28)), DateTime(2026, 9, 28));
      expect(weekStart(DateTime(2026, 9, 27)), DateTime(2026, 9, 21));
    });
  });

  group('comparación con la comunidad', () {
    test('quita mi nota del promedio de cada disco y salta los que solo califiqué yo', () {
      final mine = [
        _r('a', 9, at: now),
        _r('b', 7, at: now),
        _r('solo', 10, at: now),
      ];
      final c = communityComparison(mine, {
        'a': _stats('a', count: 3, sum: 9 + 6 + 8), // los demás: 7
        'b': _stats('b', count: 2, sum: 7 + 5), // los demás: 5
        'solo': _stats('solo', count: 1, sum: 10),
      })!;
      expect(c.albums, 2);
      expect(c.mine, 8);
      expect(c.community, 6);
      final parts = comparisonSentence(c, _es);
      expect(parts.before, 'Calificas ');
      expect(parts.accent, '2,0 puntos más alto');
      expect(parts.after, ' que la comunidad. Su promedio en los mismos discos es 6,0.');
      expect(comparisonSentence(c, _en).accent, '2.0 points higher');
    });

    test('más bajo, igual y sin datos', () {
      final lower = comparisonSentence((mine: 6.4, community: 7.0, albums: 3), _es);
      expect(lower.accent, '0,6 puntos más bajo');
      final same = comparisonSentence((mine: 7.02, community: 7.0, albums: 3), _es);
      expect(same.accent, 'igual');
      expect(communityComparison([_r('x', 8, at: now)], const {}), isNull);
    });

    test('las frases con énfasis se parten por los asteriscos', () {
      expect(accentParts('a *b* c'), (before: 'a ', accent: 'b', after: ' c'));
      expect(accentParts('sin énfasis'), (before: 'sin énfasis', accent: '', after: ''));
      final streak = accentParts(_es.statsStreak(6));
      expect(streak.accent, '6 semanas');
    });
  });

  group('afinidad con amigos', () {
    PersonInfo p(String uid) => PersonInfo(uid: uid, name: uid, colorValue: 0xFF000000);
    final mine = [_r('a', 9, at: now), _r('b', 8, at: now), _r('c', 3, at: now)];

    test('la más afín y la menos afín', () {
      final out = friendExtremes(mine, {
        'santi': [_r('a', 9, at: now, uid: 'santi'), _r('b', 8, at: now, uid: 'santi')],
        'tomas': [_r('a', 4, at: now, uid: 'tomas'), _r('c', 9, at: now, uid: 'tomas')],
        'nadie': [_r('zz', 7, at: now, uid: 'nadie')],
      }, [p('santi'), p('tomas'), p('nadie')]);
      expect(out.most?.person.uid, 'santi');
      expect(out.most?.percent, 100);
      expect(out.most?.common, 2);
      expect(out.least?.person.uid, 'tomas');
      expect(out.least?.percent, 45);
    });

    test('con una sola persona en común solo hay "más afín"', () {
      final out = friendExtremes(mine, {
        'santi': [_r('a', 9, at: now, uid: 'santi')],
      }, [p('santi')]);
      expect(out.most?.person.uid, 'santi');
      expect(out.least, isNull);
      expect(friendExtremes(mine, const {}, const []).most, isNull);
    });
  });

  group('géneros y países', () {
    final ratings = [
      for (var i = 0; i < 4; i++) _r('rock$i', 8, at: now, artists: [('cerati', 'Gustavo Cerati')]),
      for (var i = 0; i < 3; i++) _r('rh$i', 8, at: now, artists: [('radiohead', 'Radiohead')]),
      _r('bb', 7, at: now, artists: const [('badbunny', 'Bad Bunny')]),
      _r('x1', 7, at: now, artists: const [('a1', 'A1')]),
      _r('x2', 7, at: now, artists: const [('a2', 'A2')]),
      _r('x3', 7, at: now, artists: const [('a3', 'A3')]),
      _r('sin', 7, at: now, artists: const [('nadie', 'Sin datos')]),
    ];
    final meta = {
      'cerati': const ArtistMeta(country: 'AR', genres: ['rock en español', 'latin rock']),
      'radiohead': const ArtistMeta(country: 'GB', genres: ['alternative rock']),
      'badbunny': const ArtistMeta(country: 'PR', genres: ['reggaeton']),
      'a1': const ArtistMeta(country: 'US', genres: ['jazz']),
      'a2': const ArtistMeta(country: 'US', genres: ['folk']),
      'a3': const ArtistMeta(genres: ['ambient']),
    };

    test('los 4 géneros con más discos y "Otros" con el resto', () {
      final genres = genreShares(ratings, meta);
      expect(genres.map((g) => g.key).take(2), ['rock en español', 'alternative rock']);
      expect(genres.length, statsTopGenres + 1);
      expect(genres.last.key, '');
      expect(genres.fold<int>(0, (s, g) => s + g.count), 11);
    });

    test('países: cuántos hay y los cinco primeros', () {
      final countries = countryShares(ratings, meta);
      expect(countries.countries, 4);
      expect(countries.top.map((c) => c.key), ['AR', 'GB', 'US', 'PR']);
    });

    test('sin datos de ningún artista, no hay bloques', () {
      expect(genreShares(ratings, const {}), isEmpty);
      expect(countryShares(ratings, const {}).top, isEmpty);
    });

    test('ArtistMeta limpia lo que llega', () {
      final m = ArtistMeta.fromMap({'country': ' ar ', 'genres': ['Rock', '', 3]});
      expect(m.country, 'AR');
      expect(m.genres, ['rock']);
      expect(ArtistMeta.fromMap(const {}).country, isNull);
    });
  });

  test('tiempo escuchando: días con un decimal, o discos si es menos de un día', () {
    ProfileStats withHours(double hours, int albums) => ProfileStats(
          total: albums,
          average: 8,
          hist: const {},
          mode: 8,
          artists: const [],
          decades: const [],
          months: List.filled(12, 0),
          year: 2026,
          streakWeeks: 0,
          durationMs: (hours * Duration.millisecondsPerHour).round(),
          withDuration: albums,
        );
    expect(listeningEquivalent(withHours(41, 54), _es), '≈ 1,7 días seguidos');
    expect(listeningEquivalent(withHours(96, 128), _es), '≈ 4 días seguidos');
    expect(listeningEquivalent(withHours(6, 8), _es), '≈ 8 discos');
    expect(listeningEquivalent(withHours(41, 54), _en), '≈ 1.7 days straight');
  });

  test('altos de las barras', () {
    expect(histBarHeight(0, 15), 2);
    expect(histBarHeight(15, 15), 118);
    expect(histBarHeight(1, 15), 14 + 7);
    expect(monthBarHeight(0, 9), 2);
    expect(monthBarHeight(9, 9), 76);
    expect(StatsShareCard.barHeight(15, 15), 68);
    expect(StatsShareCard.barHeight(0, 15), 2);
  });

  testWidgets('la tarjeta para compartir cabe en 270×480 en los tres fondos y los dos idiomas',
      (tester) async {
    final data = StatsCardData(
      handle: '@un.usuario.bastante.largo',
      period: StatsPeriod.year,
      date: now,
      since: 2025,
      total: 154,
      average: 7.4,
      hist: const [0, 1, 1, 2, 4, 7, 12, 15, 9, 3],
      mode: 8,
      artist: 'Un artista con un nombre larguísimo que no cabe en una línea',
      link: Uri.parse('https://red-social-c786b.web.app/u/un.usuario.bastante.largo'),
    );
    for (final locale in const [Locale('es'), Locale('en')]) {
      for (final theme in StatsCardTheme.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildViniloTheme(ViniloPalette.dark),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Center(
              child: StatsShareCard(data: data, theme: theme, accent: ViniloPalette.defaultAccent),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$locale $theme');
        expect(tester.getSize(find.byType(StatsShareCard)), StatsShareCard.size);
      }
    }
    expect(find.text('MY YEAR\nIN RECORDS'), findsOneWidget);
    expect(find.text('7.4'), findsOneWidget);
    expect(find.text('red-social-c786b.web.app/u/un.usuario.bastante.largo'), findsOneWidget);
  });
}
