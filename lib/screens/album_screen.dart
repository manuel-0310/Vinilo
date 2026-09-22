import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_strip.dart';
import '../widgets/histogram.dart';
import '../widgets/misc.dart';
import '../widgets/rating_dial.dart';
import '../widgets/rating_sheet.dart';
import '../widgets/score_widgets.dart';
import '../widgets/user_avatar.dart';
import 'routes.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.album, required this.heroTag});

  final Album album;
  final String heroTag;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Services? _services;
  AlbumDetail? _detail;
  Object? _detailError;
  Color? _glow;
  Future<AlbumPage>? _more;
  Stream<AlbumStats?>? _stats;
  Stream<RatingEntry?>? _mine;
  Stream<List<RatingEntry>>? _community;

  /// Nota elegida en el dial de la pantalla, antes de confirmarla en la hoja.
  int? _pending;

  Album get _album => _detail ?? widget.album;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    _services = services;
    _stats = services.ratings.albumStats(widget.album.id);
    _mine = services.ratings.myRating(me.uid, widget.album.id);
    _community = services.ratings.albumRatings(widget.album.id);
    _detail = services.spotify.cachedAlbum(widget.album.id);
    if (_detail == null) {
      _loadDetail();
    } else {
      _loadMore();
    }
    _loadPalette();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _services!.spotify.album(widget.album.id);
      if (!mounted) return;
      setState(() => _detail = detail);
      _loadMore();
    } catch (e) {
      if (!mounted) return;
      setState(() => _detailError = e);
    }
  }

  void _loadMore() {
    final ids = _album.artistIds;
    if (ids.isEmpty || _more != null) return;
    final future = _services!.spotify.artistAlbums(ids.first);
    setState(() {
      _more = future;
    });
  }

  Future<void> _loadPalette() async {
    final color = await _services!.palette.dominant(
      widget.album.smallCover ?? widget.album.bestCover,
    );
    if (color != null && mounted) setState(() => _glow = color);
  }

  Future<void> _rate(RatingEntry? existing, {int? initialScore}) async {
    final result = await showRatingSheet(
      context,
      album: _album,
      existing: existing,
      initialScore: initialScore,
    );
    if (!mounted) return;
    setState(() => _pending = null);
    if (result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == RatingSheetResult.saved
              ? 'Guardado en tu diario'
              : 'Nota borrada de tu diario',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final album = _album;
    final detail = _detail;
    final glow = _glow ?? c.surface3;
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final coverSize = math.min(size.width * 0.7, 330.0);

    final meta = [
      album.meta,
      if (detail != null && detail.tracks.isNotEmpty) detail.totalDurationLabel,
    ].join(' · ');

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // El resplandor vive dentro del encabezado: sube con la portada
              // y desaparece; el resto del contenido queda sobre el fondo liso.
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -AmbientGlow.bleed,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AmbientGlow(color: glow),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: topPad + 66),
                      child: Column(
                        children: [
                          Center(
                            child: AlbumCover(
                              url: album.bestCover,
                              size: coverSize,
                              radius: 18,
                              heroTag: widget.heroTag,
                              shadow: true,
                              shadowColor: glow,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              children: [
                                Text(
                                  album.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: VText.display(36, height: 1.02),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  album.artist,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: VText.ui(16, weight: 600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  meta,
                                  textAlign: TextAlign.center,
                                  style: VText.ui(13, color: c.text3),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06),
                          const SizedBox(height: 26),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                  child: StreamBuilder<RatingEntry?>(
                    stream: _mine,
                    builder: (context, mineSnap) {
                      final mine = mineSnap.data;
                      final waiting =
                          mineSnap.connectionState == ConnectionState.waiting;
                      return Column(
                        children: [
                          if (waiting)
                            const Skeleton(height: 64, radius: 20)
                          else
                            _MyRatingBlock(
                              entry: mine,
                              pending: _pending,
                              onPending: (v) => setState(() => _pending = v),
                              onCommit: (v) => _rate(null, initialScore: v),
                              onEdit: () => _rate(mine),
                            ),
                          const SizedBox(height: 14),
                          StreamBuilder<AlbumStats?>(
                            stream: _stats,
                            builder: (context, statsSnap) => _CommunityBlock(
                              stats: statsSnap.data,
                              highlight: mine?.score,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (detail == null && _detailError == null) ...[
                const SliverToBoxAdapter(child: SectionHeader('Canciones')),
                SliverList.separated(
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: VSpace.page),
                    child: Skeleton(height: 18, radius: 6),
                  ),
                ),
              ] else if (_detailError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'No se pudo cargar el detalle: $_detailError',
                            style: VText.ui(13, color: c.danger),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _detailError = null);
                            _loadDetail();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (detail!.tracks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    'Canciones',
                    subtitle:
                        '${plural(detail.tracks.length, 'canción', 'canciones')} · ${detail.totalDurationLabel}',
                  ),
                ),
                SliverList.separated(
                  itemCount: detail.tracks.length,
                  separatorBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.only(left: VSpace.page + 32, right: VSpace.page),
                    child: Divider(),
                  ),
                  itemBuilder: (_, i) => _TrackRow(
                    track: detail.tracks[i],
                    albumArtist: detail.artist,
                  ),
                ),
              ],
              StreamBuilder<List<RatingEntry>>(
                stream: _community,
                builder: (context, snap) {
                  final entries = snap.data ?? const <RatingEntry>[];
                  if (entries.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SectionHeader(
                          'Lo que dice la comunidad',
                          subtitle: plural(entries.length, 'nota', 'notas'),
                        ),
                      ),
                      SliverList.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _CommunityRow(entry: entries[i])
                            .animate()
                            .fadeIn(delay: (40 * (i % 8)).ms),
                      ),
                    ],
                  );
                },
              ),
              FutureBuilder<AlbumPage>(
                future: _more,
                builder: (context, snap) {
                  final items = (snap.data?.items ?? const <Album>[])
                      .where((a) => a.id != album.id)
                      .toList();
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader('Más de ${album.artist}'),
                        AlbumStrip(
                          albums: items,
                          heroPrefix: 'more-${album.id}',
                          size: 124,
                        ),
                      ],
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    VSpace.page,
                    34,
                    VSpace.page,
                    bottomPad + 30,
                  ),
                  child: Text(
                    [
                      if (detail?.label != null) detail!.label!,
                      if (detail?.copyright != null) detail!.copyright!,
                      if (album.releaseDate != null)
                        'Publicado el ${album.releaseDate}',
                      'Datos y portadas de Spotify',
                    ].join('\n'),
                    style: VText.ui(11, color: c.text3, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: topPad + 8,
            left: 16,
            child: GlassIconButton(
              key: const ValueKey('back'),
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRatingBlock extends StatelessWidget {
  const _MyRatingBlock({
    required this.entry,
    required this.pending,
    required this.onPending,
    required this.onCommit,
    required this.onEdit,
  });

  final RatingEntry? entry;
  final int? pending;
  final ValueChanged<int> onPending;
  final ValueChanged<int> onCommit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final e = entry;
    if (e != null) {
      // Ya calificado: una sola fila, "Tu nota 8 ·········· Editar".
      final color = c.score(e.score);
      return Container(
        key: ValueKey('rated-${e.score}'),
        padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Text('Tu nota', style: VText.ui(15, weight: 600)),
            const SizedBox(width: 12),
            ScoreNumeral(score: e.score, size: 30),
            const SizedBox(width: 14),
            Expanded(child: _DotLeader(color: c.text3)),
            const SizedBox(width: 4),
            TextButton(
              key: const ValueKey('rating-edit'),
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: c.accent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Editar', style: VText.ui(14, weight: 700, color: c.accent)),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }
    // Sin nota todavía: el dial grande, aquí mismo.
    final p = pending;
    final color = p == null ? c.text3 : c.score(p);
    return Container(
      key: const ValueKey('unrated'),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TU NOTA', style: VText.label(11, color: color)),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  p == null ? 'Toca o desliza para elegir' : '$p · ${Score.label(p)}',
                  key: ValueKey(p),
                  style: VText.display(18, italic: true, color: color),
                ),
              ),
            ],
          ),
          RatingDial(value: p, onChanged: onPending, onCommit: onCommit),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Línea de puntos que rellena el espacio entre la nota y "Editar".
class _DotLeader extends StatelessWidget {
  const _DotLeader({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: CustomPaint(painter: _DotPainter(color)),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final y = size.height / 2;
    for (var x = 2.0; x < size.width; x += 7) {
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) => old.color != color;
}

class _CommunityBlock extends StatelessWidget {
  const _CommunityBlock({required this.stats, this.highlight});

  final AlbumStats? stats;
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final s = stats;
    final decoration = BoxDecoration(
      color: c.surface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: c.line),
    );
    if (s == null || s.count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'Nadie ha calificado este disco todavía',
          textAlign: TextAlign.center,
          style: VText.ui(14, color: c.text2),
        ),
      );
    }
    final color = c.score(s.average);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COMUNIDAD', style: VText.label(11, color: c.text3)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    Score.formatAverage(s.average),
                    style: VText.display(56, color: color, height: 0.95),
                  ),
                  const SizedBox(width: 6),
                  Text('/10', style: VText.ui(14, color: c.text3)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plural(s.count, 'nota', 'notas'),
                style: VText.ui(13, color: c.text2),
              ),
            ],
          ),
          const SizedBox(width: 22),
          Expanded(
            child: ScoreHistogram(hist: s.hist, highlight: highlight),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.albumArtist});

  final Track track;
  final String albumArtist;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final showArtists = track.artists.isNotEmpty && track.artists != albumArtist;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${track.number}',
              style: VText.ui(13, color: c.text3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.ui(15, weight: 600),
                ),
                if (showArtists)
                  Text(
                    track.artists,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12, color: c.text2),
                  ),
              ],
            ),
          ),
          if (track.explicit)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: c.text3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('E', style: VText.label(9, color: c.text3)),
              ),
            ),
          Text(track.duration, style: VText.ui(13, color: c.text3)),
        ],
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({required this.entry});

  final RatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      child: Material(
        color: c.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openUser(context, entry.user.uid),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(
                  name: entry.user.name,
                  color: entry.user.color,
                  url: entry.user.avatarUrl,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(14, weight: 700),
                            ),
                          ),
                          Text(
                            timeAgo(entry.updatedAt),
                            style: VText.ui(11, color: c.text3),
                          ),
                        ],
                      ),
                      if (entry.hasNote) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.note,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: VText.display(17, italic: true, height: 1.2),
                        ),
                      ] else
                        Text(
                          Score.label(entry.score),
                          style: VText.ui(12, color: c.text2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ScoreNumeral(score: entry.score, size: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
