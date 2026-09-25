import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/artist_stats.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/oklch.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/share_links.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/share_button.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_ruler.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// Ficha de un artista: volver y compartir, la foto redonda de 140,
/// "Artista · N discos" y el nombre; su calificación en Vinilo (promedio
/// ponderado de todas las notas a sus discos) con el histograma, y la
/// discografía, que se ordena por recientes o por mejor calificados y se
/// carga por páginas al llegar al final.
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
  AlbumPage? _albums;
  Object? _albumsError;
  bool _loadingMore = false;
  Stream<List<AlbumStats>>? _stats;

  /// "Mejor calificados ↓" en lugar de "Recientes ↓".
  bool _bestFirst = false;

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
      if (mounted) setState(() => _detail = detail);
    } catch (_) {
      // Sin ficha se queda con lo que se sabía al abrir (nombre y foto).
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
    final l10n = context.l10n;
    final artist = _artist;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final page = _albums;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<AlbumStats>>(
          stream: _stats,
          builder: (context, statsSnap) {
            final stats = statsSnap.data ?? const <AlbumStats>[];
            final byAlbum = {for (final s in stats) s.album.id: s};
            final summary = ArtistSummary.from(stats);
            final albums = sortDiscography(
              page?.items ?? const <Album>[],
              byAlbum,
              bestFirst: _bestFirst,
            );
            return NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Row(
                        children: [
                          VIconButton(
                            key: const ValueKey('back'),
                            icon: VIcon.back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          ShareButton(
                            key: const ValueKey('share-artist'),
                            style: VIconButtonStyle.bordered,
                            message: (l) => shareArtistMessage(artist, l),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ArtistAvatar(artist: artist, size: 140),
                          const SizedBox(height: 14),
                          VMono(
                            page == null
                                ? l10n.artistLabel
                                : '${l10n.artistLabel} · ${l10n.countAlbums(page.total)}',
                            key: const ValueKey('artist-overline'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            artist.name,
                            key: const ValueKey('artist-name'),
                            style: VText.display(64, weight: 800, height: 0.86, tracking: 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 20, VSpace.page, 0),
                      child: _ArtistScoreBlock(summary: summary, waiting: !statsSnap.hasData),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: VSectionHeader(
                        page == null
                            ? l10n.artistDiscography
                            : '${l10n.artistDiscography} · ${l10n.countAlbums(page.total)}',
                        action: '${_bestFirst ? l10n.artistSortBest : l10n.listsSortRecent} ↓',
                        actionKey: const ValueKey('artist-sort'),
                        accentAction: false,
                        onAction: () => setState(() => _bestFirst = !_bestFirst),
                      ),
                    ),
                  ),
                  if (page == null && _albumsError == null)
                    SliverList.builder(
                      itemCount: 5,
                      itemBuilder: (_, _) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineSoft))),
                        child: const Row(
                          children: [
                            VSkeleton(width: 56, height: 56),
                            SizedBox(width: 12),
                            Expanded(child: VSkeleton(height: 30)),
                          ],
                        ),
                      ),
                    )
                  else if (albums.isEmpty && _albumsError == null)
                    SliverToBoxAdapter(
                      child: VEmptyState(
                        title: l10n.artistNoAlbumsTitle,
                        message: l10n.artistNoAlbumsBody,
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: albums.length,
                      itemBuilder: (_, i) => _AlbumRow(
                        key: ValueKey('artist-album-$i'),
                        album: albums[i],
                        stats: byAlbum[albums[i].id],
                        heroTag: 'artist-${artist.id}-${albums[i].id}',
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, bottomPad + 30),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineSoft))),
                      child: _albumsError != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.artistAlbumsError(describeError(_albumsError, l10n)),
                                  style: VText.ui(13, color: c.danger, height: 1.35),
                                ),
                                const SizedBox(height: 10),
                                VTextLink(l10n.retry, key: const ValueKey('artist-retry'), onTap: _loadAlbums),
                              ],
                            )
                          : _loadingMore && page != null
                              ? Center(
                                  child: SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 1.6, color: c.ink3),
                                  ),
                                )
                              : page != null && page.nextOffset == null
                                  ? VMono(l10n.spotifyCredit, size: 10, tracking: 0.04, color: c.ink4, uppercase: false)
                                  : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Calificación": el promedio en 72 en énfasis con " /10" y "N notas · M
/// discos"; a la derecha, el histograma de 60 con "1" y "10" en las puntas.
class _ArtistScoreBlock extends StatelessWidget {
  const _ArtistScoreBlock({required this.summary, required this.waiting});

  final ArtistSummary summary;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final average = summary.average;
    final big = VText.display(72, weight: 700, height: 0.85, tracking: 0);
    return Container(
      key: ValueKey(average == null && !waiting ? 'artist-unrated' : 'artist-score'),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VMono(l10n.ratingLabel),
              const SizedBox(height: 4),
              if (waiting)
                const VSkeleton(width: 96, height: 61)
              else
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: average == null ? '—' : Score.formatAverage(average, l10n.localeName),
                        style: TextStyle(color: average == null ? c.inkA(0.28) : c.accent),
                      ),
                      if (average != null)
                        TextSpan(text: ' /10', style: VText.ui(14, weight: 500, color: c.ink4)),
                    ],
                  ),
                  style: big,
                ),
              const SizedBox(height: 4),
              Text(
                average == null
                    ? l10n.artistNoRatings
                    : '${l10n.countRatings(summary.count)} · ${l10n.countAlbums(summary.ratedAlbums)}',
                style: VText.ui(12.5, color: c.ink3),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Histogram10(counts: summary.hist, height: 60, barMargin: 1),
                const SizedBox(height: 5),
                const RulerNumbers(onlyEnds: true, fontSize: 9.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un disco de la discografía: portada de 56, título, "2025 · Álbum · 1
/// nota" (o "Sin notas") y su promedio en el tono de su portada, o "—".
class _AlbumRow extends StatefulWidget {
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
  State<_AlbumRow> createState() => _AlbumRowState();
}

class _AlbumRowState extends State<_AlbumRow> {
  Color? _coverColor;
  String? _askedFor;

  bool get _rated => (widget.stats?.count ?? 0) > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _askPalette();
  }

  @override
  void didUpdateWidget(_AlbumRow old) {
    super.didUpdateWidget(old);
    if (old.album.id != widget.album.id) _coverColor = null;
    _askPalette();
  }

  /// El tono solo hace falta si el disco tiene nota; sale de la portada
  /// pequeña, con la caché de `PaletteService`.
  void _askPalette() {
    final url = widget.album.smallCover;
    if (!_rated || url == null || _askedFor == url) return;
    _askedFor = url;
    final palette = ServicesScope.of(context).palette;
    // Si ya se sacó (al cambiar el orden, por ejemplo), sin esperar.
    final known = palette.cached(url);
    if (known != null) {
      _coverColor = known;
      return;
    }
    palette.dominant(url).then((color) {
      if (color != null && mounted && _askedFor == url) setState(() => _coverColor = color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final album = widget.album;
    final s = widget.stats;
    final rated = _rated;
    final cover = _coverColor;
    return Pressable(
      onTap: () => openAlbum(context, album, heroTag: widget.heroTag),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(top: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            AlbumCover(url: album.smallCover, size: 56, heroTag: widget.heroTag),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(15, weight: 600),
                  ),
                  const SizedBox(height: 4),
                  VMono(
                    [
                      if (album.year != null) '${album.year}',
                      album.typeLabel(l10n),
                      rated ? l10n.countRatings(s!.count) : l10n.artistNoRatings,
                    ].join(' · '),
                    size: 10,
                    tracking: 0.06,
                    color: c.inactive,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              rated ? Score.formatAverage(s!.average, l10n.localeName) : '—',
              style: VText.display(
                34,
                weight: 700,
                height: 1,
                tracking: 0,
                color: !rated
                    ? c.inkA(0.25)
                    : cover == null
                        ? c.accent
                        : coverTone(cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
