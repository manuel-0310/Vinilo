import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/artist_stats.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/histogram.dart';
import '../widgets/misc.dart';
import 'routes.dart';

/// Ficha de un artista: foto, nombre, géneros, su calificación en Vinilo
/// (promedio ponderado de todas las notas a sus discos) y su discografía,
/// que se carga por páginas al llegar al final.
class ArtistScreen extends StatefulWidget {
  const ArtistScreen({super.key, required this.artist});

  /// Lo que se sabe del artista al abrir (al menos id y nombre); la ficha
  /// completa se pide a Spotify.
  final Artist artist;

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  Services? _services;
  Artist? _detail;
  Object? _detailError;
  Color? _glow;
  AlbumPage? _albums;
  Object? _albumsError;
  bool _loadingMore = false;
  Stream<List<AlbumStats>>? _stats;

  Artist get _artist => _detail ?? widget.artist;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = ServicesScope.of(context);
    _stats = _services!.ratings.artistAlbumStats(widget.artist.id);
    _loadDetail();
    _loadAlbums();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _services!.spotify.artist(widget.artist.id);
      if (!mounted) return;
      setState(() => _detail = detail);
      final color = await _services!.palette.dominant(detail.bestImage);
      if (color != null && mounted) setState(() => _glow = color);
    } catch (e) {
      if (mounted) setState(() => _detailError = e);
    }
  }

  Future<void> _loadAlbums() async {
    final next = _albums?.nextOffset ?? 0;
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
      _albumsError = null;
    });
    try {
      final page = await _services!.spotify.artistAlbums(
        widget.artist.id,
        offset: next,
      );
      if (!mounted) return;
      setState(() => _albums = _albums == null ? page : _albums!.merge(page));
    } catch (e) {
      if (mounted) setState(() => _albumsError = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels > n.metrics.maxScrollExtent - 400 &&
        _albums?.nextOffset != null &&
        !_loadingMore &&
        _albumsError == null) {
      _loadAlbums();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final artist = _artist;
    final glow = _glow ?? c.surface3;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final albums = _albums?.items ?? const <Album>[];

    return Scaffold(
      body: StreamBuilder<List<AlbumStats>>(
        stream: _stats,
        builder: (context, statsSnap) {
          final stats = statsSnap.data ?? const <AlbumStats>[];
          final byAlbum = {for (final s in stats) s.album.id: s};
          final summary = ArtistSummary.from(stats);
          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
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
                          // Todo el ancho: dentro del Stack, un Column suelto
                          // queda arriba a la izquierda con el ancho de su hijo
                          // más ancho, y con nombres cortos se descentraba.
                          Padding(
                            padding: EdgeInsets.only(top: topPad + 66),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  ArtistAvatar(artist: artist, size: 168, shadowColor: glow),
                                  const SizedBox(height: 22),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 28),
                                    child: Column(
                                      children: [
                                        Text(
                                          artist.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: VText.display(38, height: 1),
                                        ),
                                        if (artist.genres.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            artist.genres.take(4).join(' · '),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: VText.ui(13, color: c.text2),
                                          ),
                                        ] else if (_detail != null || _detailError != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Artista',
                                            style: VText.ui(13, color: c.text3),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06),
                                  const SizedBox(height: 26),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                        child: _ArtistScoreBlock(summary: summary, waiting: !statsSnap.hasData),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        'Discografía',
                        subtitle: _albums == null
                            ? null
                            : plural(_albums!.total, 'disco', 'discos'),
                      ),
                    ),
                    if (_albums == null && _albumsError == null)
                      SliverList.separated(
                        itemCount: 5,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, _) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: VSpace.page),
                          child: Skeleton(height: 72, radius: 16),
                        ),
                      )
                    else if (albums.isEmpty && _albumsError == null)
                      const SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'Sin discos',
                          message: 'Spotify no tiene álbumes de este artista.',
                        ),
                      )
                    else
                      SliverList.separated(
                        itemCount: albums.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _AlbumRow(
                          key: ValueKey('artist-album-$i'),
                          album: albums[i],
                          stats: byAlbum[albums[i].id],
                          heroTag: 'artist-${artist.id}-${albums[i].id}',
                        ).animate().fadeIn(delay: (30 * (i % 10)).ms),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(VSpace.page, 20, VSpace.page, 0),
                        child: Center(
                          child: _albumsError != null
                              ? Column(
                                  children: [
                                    Text(
                                      'No se pudo cargar la discografía: $_albumsError',
                                      textAlign: TextAlign.center,
                                      style: VText.ui(13, color: c.danger),
                                    ),
                                    TextButton(
                                      onPressed: _loadAlbums,
                                      child: const Text('Reintentar'),
                                    ),
                                  ],
                                )
                              : _loadingMore && _albums != null
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : _albums != null && _albums!.nextOffset == null
                                      ? Text(
                                          'Datos y portadas de Spotify',
                                          style: VText.ui(11, color: c.text3),
                                        )
                                      : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
                  ],
                ),
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
          );
        },
      ),
    );
  }
}

class _ArtistScoreBlock extends StatelessWidget {
  const _ArtistScoreBlock({required this.summary, required this.waiting});

  final ArtistSummary summary;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    if (waiting) return const Skeleton(height: 110, radius: 24);
    final average = summary.average;
    if (average == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'Nadie ha calificado un disco de este artista todavía',
          key: const ValueKey('artist-unrated'),
          textAlign: TextAlign.center,
          style: VText.ui(14, color: c.text2),
        ),
      );
    }
    final color = c.score(average);
    return Container(
      key: const ValueKey('artist-score'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CALIFICACIÓN', style: VText.label(11, color: c.text3)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    Score.formatAverage(average),
                    style: VText.display(56, color: color, height: 0.95),
                  ),
                  const SizedBox(width: 6),
                  Text('/10', style: VText.ui(14, color: c.text3)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${plural(summary.count, 'nota', 'notas')} · ${plural(summary.ratedAlbums, 'disco', 'discos')}',
                style: VText.ui(13, color: c.text2),
              ),
            ],
          ),
          const SizedBox(width: 22),
          Expanded(child: ScoreHistogram(hist: summary.hist)),
        ],
      ),
    );
  }
}

/// Un disco de la discografía con su promedio en Vinilo (si lo tiene).
class _AlbumRow extends StatelessWidget {
  const _AlbumRow({
    super.key,
    required this.album,
    required this.stats,
    required this.heroTag,
  });

  final Album album;
  final AlbumStats? stats;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final s = stats;
    final rated = s != null && s.count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      child: Material(
        color: c.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openAlbum(context, album, heroTag: heroTag),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                AlbumCover(url: album.smallCover, size: 60, radius: 10, heroTag: heroTag),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(15, weight: 700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (album.year != null) '${album.year}',
                          album.typeLabel,
                          if (rated) plural(s.count, 'nota', 'notas'),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(12, color: c.text2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (rated)
                  Text(
                    Score.formatAverage(s.average),
                    style: VText.display(30, color: c.score(s.average), height: 1),
                  )
                else
                  Text('–', style: VText.display(30, color: c.text3, height: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

