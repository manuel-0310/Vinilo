import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../models/moderation.dart';
import '../models/rating.dart';
import '../models/stats.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/music_meta.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';
import 'share_stats_screen.dart';

/// La pestaña "Estadísticas" del perfil propio: el filtro de periodo (Este
/// mes / Este año / Siempre) y, debajo, el resumen con la comparación con la
/// comunidad, "Cómo calificas", los artistas, las décadas, el ritmo del
/// año, el tiempo escuchado, los géneros y países (si hay de dónde
/// sacarlos), la afinidad con amigos y "Compartir mis estadísticas". Todo
/// sale de mis notas; lo demás se pide una vez al abrirla.
class ProfileStatsTab extends StatefulWidget {
  const ProfileStatsTab({super.key, required this.profile, required this.ratings});

  final UserProfile profile;

  /// Todas mis notas (null mientras cargan).
  final List<RatingEntry>? ratings;

  @override
  State<ProfileStatsTab> createState() => _ProfileStatsTabState();
}

typedef _Friends = ({List<PersonInfo> people, Map<String, List<RatingEntry>> ratings});

class _ProfileStatsTabState extends State<ProfileStatsTab> {
  StatsPeriod _period = StatsPeriod.year;

  /// La barra tocada de "Cómo calificas" (null = la nota más común).
  int? _histPick;

  /// Los agregados de mis discos, para compararme con la comunidad. Se
  /// vuelven a pedir si cambia qué discos tengo calificados.
  Future<Map<String, AlbumStats>>? _community;
  int _communityKey = 0;

  /// País y géneros de mis artistas: lo que ya está en `artistMeta` y lo
  /// que se va encontrando ahora (`_foundMeta`).
  Future<Map<String, ArtistMeta>>? _meta;
  int _metaKey = 0;
  final Map<String, ArtistMeta> _foundMeta = {};

  /// Los artistas que ya se le pidieron a la función en esta sesión.
  final Set<String> _metaAsked = {};
  bool _fillingMeta = false;

  /// A quién sigo y sus notas, para la afinidad.
  Future<_Friends>? _friends;

  /// Las notas a las que ya se les buscó la duración del disco en esta
  /// sesión, y si hay una tanda en curso.
  final Set<String> _durationAsked = {};
  bool _fillingDurations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _friends ??= _loadFriends(
      ServicesScope.of(context),
      widget.profile.uid,
      Moderation.of(context),
    );
    _refresh();
  }

  @override
  void didUpdateWidget(ProfileStatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.ratings, widget.ratings)) _refresh();
  }

  static Future<_Friends> _loadFriends(Services services, String uid, ModerationState moderation) async {
    final people = moderation.people(await services.follows.following(uid).first);
    final ratings = await services.ratings.ratingsOf(people.map((p) => p.uid));
    return (people: people, ratings: ratings);
  }

  /// Pide lo que depende de qué discos tengo calificados (solo si cambió) y
  /// completa las duraciones que falten.
  void _refresh() {
    final ratings = widget.ratings;
    if (ratings == null) return;
    final services = ServicesScope.of(context);
    final albumIds = [for (final r in ratings) r.albumId]..sort();
    final albumsKey = Object.hashAll(albumIds);
    if (_community == null || albumsKey != _communityKey) {
      _communityKey = albumsKey;
      _community = services.ratings.albumStatsFor(albumIds);
    }
    final artistIds = {for (final r in ratings) ...r.album.artistIds}.toList()..sort();
    final artistsKey = Object.hashAll(artistIds);
    if (_meta == null || artistsKey != _metaKey) {
      _metaKey = artistsKey;
      _meta = _loadMeta(services, artistIds);
    }
    _fillDurations(services, ratings);
  }

  /// Lo que ya se sabe de mis artistas y, para los que faltan, la búsqueda
  /// en MusicBrainz (por la función `spotify`) sin esperarla.
  Future<Map<String, ArtistMeta>> _loadMeta(Services services, List<String> ids) async {
    final known = await services.ratings.artistMeta(ids);
    final missing = [for (final id in ids) if (!known.containsKey(id)) id];
    if (missing.isNotEmpty) unawaited(_fillMeta(services, missing));
    return known;
  }

  /// Pide a la función los artistas sin país ni géneros, de a 10; ella
  /// resuelve unos pocos por vez (MusicBrainz admite una petición por
  /// segundo) y dice cuáles quedaron: se repite hasta 8 veces por sesión.
  /// Lo encontrado se pinta en cuanto llega.
  Future<void> _fillMeta(Services services, List<String> missing) async {
    if (_fillingMeta) return;
    var queue = [for (final id in missing) if (_metaAsked.add(id)) id];
    if (queue.isEmpty) return;
    _fillingMeta = true;
    for (var round = 0; round < 8 && queue.isNotEmpty && mounted; round++) {
      final batch = queue.take(10).toList();
      try {
        final result = await services.spotify.artistMeta(batch);
        if (!mounted) break;
        if (result.meta.isNotEmpty) setState(() => _foundMeta.addAll(result.meta));
        final pending = result.pending.toSet();
        queue = [...queue.skip(batch.length), ...batch.where(pending.contains)];
        // Nada nuevo en esta vuelta: MusicBrainz no responde; otro día.
        if (result.meta.isEmpty) break;
      } catch (_) {
        // Sin conexión o sin la ruta desplegada: se queda como está.
        break;
      }
    }
    _fillingMeta = false;
  }

  /// Las notas de antes no guardan cuánto dura el disco: se le pregunta a
  /// Spotify (de a tres, hasta 45 por tanda) y se guarda en la nota, así
  /// solo pasa una vez. Al guardarse, las notas llegan de nuevo y el tiempo
  /// se recalcula solo.
  Future<void> _fillDurations(Services services, List<RatingEntry> ratings) async {
    if (_fillingDurations) return;
    final missing = [
      for (final r in ratings)
        if (r.album.durationMs == null && !_durationAsked.contains(r.id)) r,
    ].take(45).toList();
    if (missing.isEmpty) return;
    _fillingDurations = true;
    _durationAsked.addAll(missing.map((r) => r.id));
    Future<void> one(RatingEntry r) async {
      try {
        final ms = (await services.spotify.album(r.albumId)).durationMs;
        if (ms != null && ms > 0) await services.ratings.setAlbumDuration(r.id, ms);
      } catch (_) {
        // Sin conexión o un disco que ya no está: se queda sin duración.
      }
    }

    for (var i = 0; i < missing.length && mounted; i += 3) {
      await Future.wait(missing.skip(i).take(3).map(one));
    }
    _fillingDurations = false;
    if (!mounted) return;
    setState(() {});
    // Si quedaron más sin duración, la siguiente tanda.
    _refresh();
  }

  void _setPeriod(StatsPeriod period) {
    HapticFeedback.selectionClick();
    setState(() {
      _period = period;
      _histPick = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final all = widget.ratings;
    final now = DateTime.now();

    final filters = Padding(
      // 16 del prototipo, menos los 12 que cada filtro trae para el toque.
      padding: const EdgeInsets.only(top: 4),
      child: VTextFilters(
        labels: [for (final p in StatsPeriod.values) p.label(l)],
        keys: [for (final p in StatsPeriod.values) 'stats-period-${p.name}'],
        selected: _period.index,
        onChanged: (i) => _setPeriod(StatsPeriod.values[i]),
      ),
    );

    if (all == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [filters, const _StatsSkeleton()],
      );
    }

    final stats = computeStats(all, period: _period, now: now);
    final inPeriod = ratingsIn(all, _period, now);
    final average = stats.average;
    final selected = _histPick ?? stats.mode;
    final months = stats.months;
    final mostInMonth = months.fold<int>(0, math.max);
    final mostInHist = stats.hist.values.fold<int>(0, math.max);
    final topArtist = stats.artists.firstOrNull;
    final mainDecade = stats.mainDecade;

    return Column(
      key: const ValueKey('stats-tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        // Resumen: discos y promedio en 72, y la comparación con la comunidad.
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: c.line)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _BigNumber(
                          key: const ValueKey('stats-total'),
                          value: '${stats.total}',
                          label: l.statsRated,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 14),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: c.line))),
                          child: _BigNumber(
                            key: const ValueKey('stats-average'),
                            value: average == null ? '—' : Score.formatAverage(average, l.localeName),
                            label: l.statsMyAverage,
                            color: average == null ? c.inkA(0.28) : c.accentText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (stats.total == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    l.statsEmptyPeriod,
                    key: const ValueKey('stats-empty-period'),
                    style: VText.ui(15, height: 1.45, color: c.ink2),
                  ),
                )
              else
                FutureBuilder<Map<String, AlbumStats>>(
                  future: _community,
                  builder: (context, snap) {
                    final comparison =
                        snap.data == null ? null : communityComparison(inPeriod, snap.data!);
                    if (comparison == null) return const SizedBox.shrink();
                    final parts = comparisonSentence(comparison, l);
                    return Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _AccentSentence(
                        key: const ValueKey('stats-compare'),
                        parts: parts,
                        style: VText.ui(15, height: 1.45, color: c.ink),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // Cómo calificas: 10 barras con su cuenta; tocar una la resalta.
        _Block(
          title: l.statsHowYouRate,
          trailing: selected == null || stats.total == 0
              ? null
              : l.statsHistSelected(stats.hist[selected] ?? 0, selected),
          trailingKey: const ValueKey('stats-hist-label'),
          trailingTracking: 0.06,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var k = 1; k <= 10; k++) ...[
                      if (k > 1) const SizedBox(width: 3),
                      Expanded(
                        child: _HistBar(
                          key: ValueKey('stats-hist-$k'),
                          count: stats.hist[k] ?? 0,
                          most: mostInHist,
                          selected: k == selected && stats.total > 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _histPick = k);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var k = 1; k <= 10; k++) ...[
                    if (k > 1) const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '$k',
                        textAlign: TextAlign.center,
                        style: VText.mono(10, tracking: 0, color: c.ink4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (stats.artists.isNotEmpty)
          _Block(
            title: l.statsTopArtists,
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Column(
                children: [
                  for (final (i, a) in stats.artists.indexed)
                    _ArtistRow(
                      key: ValueKey('stats-artist-$i'),
                      rank: i + 1,
                      artist: a,
                      share: a.count / topArtist!.count,
                      first: i == 0,
                    ),
                ],
              ),
            ),
          ),

        if (stats.decades.isNotEmpty)
          _Block(
            title: l.statsByDecade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      for (final (i, d) in stats.decades.indexed) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: d.count,
                          child: ColoredBox(color: _decadeColor(c, i, d == mainDecade)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Grid3(
                  rowGap: 10,
                  columnGap: 12,
                  children: [
                    for (final (i, d) in stats.decades.indexed)
                      Row(
                        key: ValueKey('stats-decade-${d.decade}'),
                        children: [
                          Container(width: 10, height: 10, color: _decadeColor(c, i, d == mainDecade)),
                          const SizedBox(width: 8),
                          Text(d.label, style: VText.mono(12, tracking: 0, color: c.ink)),
                          const SizedBox(width: 8),
                          Text('${d.count}', style: VText.mono(11, tracking: 0, color: c.ink4)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

        // Tu ritmo: los 12 meses del año en curso, pase lo que pase con el
        // periodo, y la racha.
        _Block(
          title: l.statsRhythm,
          trailing: l.statsRhythmLabel('${stats.year}'),
          trailingTracking: 0.06,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var m = 0; m < 12; m++) ...[
                      if (m > 0) const SizedBox(width: 3),
                      Expanded(
                        child: AnimatedContainer(
                          key: ValueKey('stats-month-$m'),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.ease,
                          height: monthBarHeight(months[m], mostInMonth),
                          color: m == now.month - 1 ? c.accent : c.inkA(0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var m = 0; m < 12; m++) ...[
                    if (m > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        DateFormat('LLLLL', l.localeName).format(DateTime(stats.year, m + 1)).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: VText.mono(9.5, tracking: 0, color: c.ink4),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              if (stats.streakWeeks > 0)
                _AccentSentence(
                  key: const ValueKey('stats-streak'),
                  parts: accentParts(l.statsStreak(stats.streakWeeks)),
                  style: VText.ui(15, height: 1.45, color: c.inkA(0.75)),
                )
              else
                Text(
                  l.statsStreakNone,
                  key: const ValueKey('stats-streak'),
                  style: VText.ui(15, height: 1.45, color: c.inkA(0.75)),
                ),
            ],
          ),
        ),

        if (stats.total > 0)
          _Block(
            title: l.statsTime,
            trailing: stats.missingDuration > 0 && _fillingDurations
                ? l.statsTimeLoading(stats.withDuration, stats.total)
                : l.statsTimeLabel,
            trailingTracking: 0.06,
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: c.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.hours}',
                    key: const ValueKey('stats-hours'),
                    style: VText.display(72, weight: 800, height: 0.8, tracking: 0, color: c.accentText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.statsTimeHours(stats.hours), style: VText.ui(16, weight: 600)),
                          const SizedBox(height: 3),
                          VMono(listeningEquivalent(stats, l), tracking: 0.06, maxLines: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Géneros y países: solo si se sabe de dónde es algún artista.
        FutureBuilder<Map<String, ArtistMeta>>(
          future: _meta,
          builder: (context, snap) {
            final meta = {...?snap.data, ..._foundMeta};
            final genres = genreShares(inPeriod, meta);
            final countries = countryShares(inPeriod, meta);
            final mostCountry = countries.top.firstOrNull?.count ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (genres.isNotEmpty)
                  _Block(
                    key: const ValueKey('stats-genres'),
                    title: l.statsGenres,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              for (final (i, g) in genres.indexed) ...[
                                if (i > 0) const SizedBox(width: 2),
                                Expanded(
                                  flex: g.count,
                                  child: ColoredBox(color: _genreColor(c, i)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                          child: Column(
                            children: [
                              for (final (i, g) in genres.indexed)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: c.lineSoft)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(width: 10, height: 10, color: _genreColor(c, i)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          g.key.isEmpty ? l.statsGenreOther : genreLabel(g.key, l.localeName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: VText.ui(15, weight: 500),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${g.percent}%',
                                        style: VText.mono(12, tracking: 0, color: c.inkA(0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (countries.top.isNotEmpty)
                  _Block(
                    key: const ValueKey('stats-countries'),
                    title: l.statsCountries,
                    trailing: l.statsCountriesCount(countries.countries),
                    trailingTracking: 0.06,
                    child: Container(
                      margin: const EdgeInsets.only(top: 14),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                      child: Column(
                        children: [
                          for (final (i, country) in countries.top.indexed)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: c.lineSoft)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      countryName(country.key, l.localeName),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: VText.ui(15, weight: 500),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Meter(
                                      value: mostCountry == 0 ? 0 : country.count / mostCountry,
                                      color: i == 0 ? c.accent : c.inkA(0.55),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${country.count}',
                                      textAlign: TextAlign.right,
                                      style: VText.mono(12, tracking: 0, color: c.inkA(0.6)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // Afinidad con amigos: la persona más afín y la menos (de siempre,
        // no del periodo). Tocarla abre la afinidad con ella.
        FutureBuilder<_Friends>(
          future: _friends,
          builder: (context, snap) {
            final data = snap.data;
            if (data == null) return const SizedBox.shrink();
            final extremes = friendExtremes(all, data.ratings, Moderation.of(context).people(data.people));
            final most = extremes.most;
            if (most == null) return const SizedBox.shrink();
            return _Block(
              key: const ValueKey('stats-friends'),
              title: l.statsFriends,
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                child: Column(
                  children: [
                    _FriendRow(key: const ValueKey('stats-friend-most'), friend: most, most: true),
                    if (extremes.least != null)
                      _FriendRow(
                        key: const ValueKey('stats-friend-least'),
                        friend: extremes.least!,
                        most: false,
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        if (stats.total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
            child: VSecondaryButton(
              key: const ValueKey('stats-share'),
              label: l.statsShare,
              fontSize: 15,
              onPressed: () => openShareStats(
                context,
                StatsCardData.from(
                  profile: widget.profile,
                  stats: stats,
                  period: _period,
                  now: now,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// La década principal va en énfasis; las demás, en tinta cada vez más
  /// clara (18 % + 10 puntos por puesto).
  static Color _decadeColor(ViniloPalette c, int index, bool main) =>
      main ? c.accent : c.inkA(math.min(0.78, 0.18 + index * 0.1));

  /// El primer género en énfasis; los demás, en tinta cada vez más apagada.
  static Color _genreColor(ViniloPalette c, int index) =>
      index == 0 ? c.accent : c.inkA(math.max(0.14, 0.62 - index * 0.12));
}

/// Alto de la barra de un mes en "Tu ritmo": 2 sin discos; con discos, de 6
/// a 76 según el mes con más.
double monthBarHeight(int count, int most) =>
    count <= 0 || most <= 0 ? 2 : 6 + (70 * count / most).roundToDouble();

/// Alto de una barra de "Cómo calificas": 2 sin discos; con discos, de 14 a
/// 118 según la nota más común.
double histBarHeight(int count, int most) =>
    count <= 0 || most <= 0 ? 2 : 14 + (104 * count / most).roundToDouble();

/// Un bloque de la pestaña: el título en 28 (y, a la derecha, un dato en
/// mono) con 30 de aire arriba.
class _Block extends StatelessWidget {
  const _Block({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.trailingKey,
    this.trailingTracking = 0.08,
  });

  final String title;
  final String? trailing;
  final Key? trailingKey;
  final double trailingTracking;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: VText.display(28, weight: 700, stretch: 70, height: 1, tracking: 0),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                VMono(trailing!, key: trailingKey, tracking: trailingTracking, maxLines: 1),
              ],
            ],
          ),
          child,
        ],
      ),
    );
  }
}

/// Un número de 72 con su etiqueta mono debajo.
class _BigNumber extends StatelessWidget {
  const _BigNumber({super.key, required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: VText.display(72, weight: 800, height: 0.8, tracking: 0, color: color),
            ),
          ),
          const SizedBox(height: 8),
          VMono(label, size: 10, maxLines: 1),
        ],
      ),
    );
  }
}

/// Una frase con un trozo en énfasis.
class _AccentSentence extends StatelessWidget {
  const _AccentSentence({super.key, required this.parts, required this.style});

  final ({String before, String accent, String after}) parts;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.before),
          TextSpan(text: parts.accent, style: TextStyle(color: c.accentText)),
          TextSpan(text: parts.after),
        ],
      ),
      style: style,
    );
  }
}

/// Una barra de "Cómo calificas": crece en 400 ms, lleva su cuenta arriba
/// y, elegida, va en énfasis con el número oscuro. Toda la columna responde
/// al toque.
class _HistBar extends StatelessWidget {
  const _HistBar({
    super.key,
    required this.count,
    required this.most,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final int most;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.ease,
          height: histBarHeight(count, most),
          width: double.infinity,
          decoration: BoxDecoration(color: selected ? c.accent : c.inkA(0.22)),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 5),
          // Recortado: mientras la barra crece, el número no se sale.
          clipBehavior: Clip.hardEdge,
          child: count <= 0
              ? null
              : Text(
                  '$count',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: VText.mono(10, tracking: 0, color: selected ? c.onAccent : c.inkA(0.7), height: 1),
                ),
        ),
      ),
    );
  }
}

/// Barra fina de avance (4 de alto) sobre un riel de tinta al 10 %.
class _Meter extends StatelessWidget {
  const _Meter({required this.value, required this.color});

  /// De 0 a 1.
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      height: 4,
      color: c.inkA(0.1),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: ColoredBox(color: color, child: const SizedBox.expand()),
      ),
    );
  }
}

/// Un artista del top: su puesto, su nombre con la barra debajo y, a la
/// derecha, cuántos discos y su promedio.
class _ArtistRow extends StatelessWidget {
  const _ArtistRow({
    super.key,
    required this.rank,
    required this.artist,
    required this.share,
    required this.first,
  });

  final int rank;
  final ArtistStat artist;

  /// Su cuenta sobre la del primero.
  final double share;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank'.padLeft(2, '0'),
              style: VText.mono(11, tracking: 0, color: c.ink4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.ui(15, weight: 600),
                ),
                const SizedBox(height: 7),
                _Meter(value: share, color: first ? c.accent : c.inkA(0.55)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l.countAlbums(artist.count),
                style: VText.mono(13, weight: 600, tracking: 0, color: c.ink),
              ),
              const SizedBox(height: 2),
              Text(
                l.statsArtistAverage(Score.formatAverage(artist.average, l.localeName)),
                style: VText.mono(10, tracking: 0, color: c.ink4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La persona más afín o la menos: avatar de 44, la etiqueta, su nombre,
/// cuántos discos en común y el porcentaje en 40. Abre la afinidad con ella.
class _FriendRow extends StatelessWidget {
  const _FriendRow({super.key, required this.friend, required this.most});

  final FriendAffinity friend;
  final bool most;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final person = friend.person;
    return Pressable(
      onTap: () => openAffinity(
        context,
        person: person,
        percent: friend.percent,
        albums: friend.albums,
      ),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(bottom: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: person.name,
              color: Color(person.colorValue),
              url: person.avatarUrl,
              size: 44,
              initialSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VMono(
                    most ? l.statsMostAffine : l.statsLeastAffine,
                    size: 10,
                    color: most ? c.accentText : c.ink3,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(16, weight: 600),
                  ),
                  const SizedBox(height: 1),
                  Text(l.statsCommon(friend.common), style: VText.ui(12.5, color: c.inactive)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${friend.percent}%',
              style: VText.display(
                40,
                weight: 800,
                height: 0.8,
                tracking: 0,
                color: most ? c.accentText : c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tres columnas iguales, en filas.
class _Grid3 extends StatelessWidget {
  const _Grid3({required this.children, required this.rowGap, required this.columnGap});

  final List<Widget> children;
  final double rowGap;
  final double columnGap;

  @override
  Widget build(BuildContext context) {
    final rows = (children.length + 2) ~/ 3;
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : rowGap),
            child: Row(
              children: [
                for (var k = 0; k < 3; k++) ...[
                  if (k > 0) SizedBox(width: columnGap),
                  Expanded(
                    child: r * 3 + k < children.length ? children[r * 3 + k] : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Mientras llegan mis notas: el resumen y el histograma en bloques.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, 0),
      child: VShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: VSkeleton(height: 86)),
                SizedBox(width: 14),
                Expanded(child: VSkeleton(height: 86)),
              ],
            ),
            SizedBox(height: 14),
            VSkeleton(height: 12, soft: true),
            SizedBox(height: 30),
            Align(alignment: Alignment.centerLeft, child: VSkeleton(width: 160, height: 26)),
            SizedBox(height: 16),
            VSkeleton(height: 120),
          ],
        ),
      ),
    );
  }
}
