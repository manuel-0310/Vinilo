import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../util/ranking.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_strip.dart';
import '../widgets/comment_card.dart';
import '../widgets/histogram.dart';
import '../widgets/misc.dart';
import '../widgets/rating_sheet.dart';
import '../widgets/score_widgets.dart';
import '../widgets/sheet.dart';
import 'list_form_sheet.dart';
import 'list_picker_sheet.dart';
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

  /// Selección de canciones para agregarlas a una lista.
  bool _selecting = false;
  final Set<String> _selected = {};

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

  Future<void> _rate(RatingEntry? existing) async {
    final result = await showRatingSheet(
      context,
      album: _album,
      existing: existing,
    );
    if (!mounted || result == null) return;
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

  void _snack(String text, {MusicList? list}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 3),
          action: list == null
              ? null
              : SnackBarAction(
                  label: 'Ver lista',
                  onPressed: () => openList(context, listId: list.id, initial: list),
                ),
        ),
      );
  }

  /// Hoja con las tres acciones de listas de este disco.
  Future<void> _listActions() {
    final album = _album;
    final hasTracks = _detail != null && _detail!.tracks.isNotEmpty;
    return showVSheet<void>(
      context,
      (ctx) => SheetScaffold(
        title: album.name,
        subtitle: album.artist,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetAction(
              key: const ValueKey('add-album-to-list'),
              icon: Icons.album_rounded,
              label: 'Agregar el disco a una lista',
              hint: 'A una de tus listas de discos, o a una nueva',
              onTap: () {
                Navigator.of(ctx).pop();
                _addAlbumToList();
              },
            ),
            const SizedBox(height: 10),
            SheetAction(
              key: const ValueKey('select-tracks'),
              icon: Icons.checklist_rounded,
              label: 'Agregar canciones a una lista',
              hint: hasTracks ? 'Elige cuáles' : 'Espera a que carguen las canciones',
              enabled: hasTracks,
              onTap: () {
                Navigator.of(ctx).pop();
                _startSelecting();
              },
            ),
            const SizedBox(height: 10),
            SheetAction(
              key: const ValueKey('create-list-from-album'),
              icon: Icons.playlist_add_rounded,
              label: 'Crear lista con este disco',
              hint: hasTracks
                  ? 'Todas sus canciones, en orden, listas para ordenar'
                  : 'Espera a que carguen las canciones',
              enabled: hasTracks,
              onTap: () {
                Navigator.of(ctx).pop();
                _createListFromAlbum();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAlbumToList() async {
    final list = await showListPicker(context, itemType: ListItemType.albums);
    if (list == null || !mounted) return;
    try {
      final outcome = await _services!.lists.addTo(list.id, [ListItem.fromAlbum(_album)]);
      _snack('${outcome.message(ListItemType.albums)} · ${list.name}', list: list);
    } catch (e) {
      _snack('No se pudo agregar: $e');
    }
  }

  Future<void> _createListFromAlbum() async {
    final detail = _detail;
    if (detail == null) return;
    final draft = await showListForm(
      context,
      title: 'Lista con este disco',
      initialName: detail.name,
      fixedItemType: ListItemType.tracks,
      submitLabel: 'Crear lista',
    );
    if (draft == null || !mounted) return;
    try {
      final me = CurrentUser.of(context);
      final list = await _services!.lists.create(
        owner: me,
        name: draft.name,
        description: draft.description,
        kind: draft.kind,
        itemType: ListItemType.tracks,
        items: [for (final t in detail.tracks) ListItem.fromTrack(t, detail)],
      );
      if (mounted) openList(context, listId: list.id, initial: list);
    } catch (e) {
      _snack('No se pudo crear la lista: $e');
    }
  }

  void _startSelecting({String? first}) {
    HapticFeedback.selectionClick();
    setState(() {
      _selecting = true;
      _selected.clear();
      if (first != null) _selected.add(first);
    });
  }

  void _stopSelecting() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleTrack(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  Future<void> _addSelectedToList() async {
    final detail = _detail;
    if (detail == null || _selected.isEmpty) return;
    final list = await showListPicker(context, itemType: ListItemType.tracks);
    if (list == null || !mounted) return;
    final items = [
      for (final t in detail.tracks)
        if (_selected.contains(t.id)) ListItem.fromTrack(t, detail),
    ];
    try {
      final outcome = await _services!.lists.addTo(list.id, items);
      _stopSelecting();
      _snack('${outcome.message(ListItemType.tracks)} · ${list.name}', list: list);
    } catch (e) {
      _snack('No se pudo agregar: $e');
    }
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
      body: StreamBuilder<RatingEntry?>(
        stream: _mine,
        builder: (context, mineSnap) {
          final mine = mineSnap.data;
          final waitingMine = mineSnap.connectionState == ConnectionState.waiting;
          final showRateButton = !waitingMine && mine == null && !_selecting;
          return Stack(
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
                                    _ArtistLink(album: album),
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
                      child: Column(
                        children: [
                          if (waitingMine)
                            const Skeleton(height: 64, radius: 20)
                          else if (mine != null)
                            _MyRatingRow(entry: mine, onEdit: () => _rate(mine)),
                          if (waitingMine || mine != null) const SizedBox(height: 14),
                          StreamBuilder<AlbumStats?>(
                            stream: _stats,
                            builder: (context, statsSnap) => _CommunityBlock(
                              stats: statsSnap.data,
                              highlight: mine?.score,
                            ),
                          ),
                        ],
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
                        subtitle: _selecting
                            ? 'Toca las que quieras agregar'
                            : '${plural(detail.tracks.length, 'canción', 'canciones')} · ${detail.totalDurationLabel}',
                        action: _selecting
                            ? TextButton(
                                key: const ValueKey('select-all'),
                                onPressed: () => setState(() {
                                  if (_selected.length == detail.tracks.length) {
                                    _selected.clear();
                                  } else {
                                    _selected.addAll(detail.tracks.map((t) => t.id));
                                  }
                                }),
                                child: Text(
                                  _selected.length == detail.tracks.length ? 'Ninguna' : 'Todas',
                                  style: VText.ui(13, weight: 700, color: c.accent),
                                ),
                              )
                            : null,
                      ),
                    ),
                    SliverList.separated(
                      itemCount: detail.tracks.length,
                      separatorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.only(left: VSpace.page + 32, right: VSpace.page),
                        child: Divider(),
                      ),
                      itemBuilder: (_, i) => _TrackRow(
                        key: ValueKey('track-$i'),
                        track: detail.tracks[i],
                        albumArtist: detail.artist,
                        selected: _selecting ? _selected.contains(detail.tracks[i].id) : null,
                        onToggle: () => _toggleTrack(detail.tracks[i].id),
                        onLongPress: _selecting
                            ? null
                            : () => _startSelecting(first: detail.tracks[i].id),
                      ),
                    ),
                  ],
                  StreamBuilder<List<RatingEntry>>(
                    stream: _community,
                    builder: (context, snap) {
                      final entries = snap.data ?? const <RatingEntry>[];
                      final all = topComments(entries);
                      if (all.isEmpty) {
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      }
                      final shown = all.take(_maxComments).toList();
                      final hidden = all.length - shown.length;
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SectionHeader(
                              'Comentarios',
                              subtitle: plural(all.length, 'comentario', 'comentarios'),
                            ),
                          ),
                          SliverList.separated(
                            itemCount: shown.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => CommentCard(
                              key: ValueKey('comment-$i'),
                              entry: shown[i],
                            ).animate().fadeIn(delay: (40 * i).ms),
                          ),
                          if (hidden > 0)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
                                child: Center(
                                  child: Pill(
                                    key: const ValueKey('comments-more'),
                                    onTap: () => openComments(
                                      context,
                                      album: album,
                                      initial: entries,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    child: Text(
                                      'Ver más ($hidden)',
                                      style: VText.ui(13, weight: 700),
                                    ),
                                  ),
                                ),
                              ),
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
                      // Con el botón flotante visible, la lista deja sitio para
                      // que las últimas canciones y este pie no queden tapados.
                      padding: EdgeInsets.fromLTRB(
                        VSpace.page,
                        34,
                        VSpace.page,
                        bottomPad + 30 + (showRateButton || _selecting ? _rateButtonClearance : 0),
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
              Positioned(
                top: topPad + 8,
                right: 16,
                child: GlassIconButton(
                  key: const ValueKey('list-actions'),
                  icon: Icons.playlist_add_rounded,
                  onTap: _listActions,
                ),
              ),
              // Botón fijo abajo mientras el disco no tenga nota mía. Al guardar
              // se va deslizándose hacia abajo y aparece la fila "Tu nota".
              // Al seleccionar canciones, en su lugar va la barra de selección.
              Positioned(
                left: VSpace.page,
                right: VSpace.page,
                bottom: bottomPad + 14,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.6),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _selecting
                      ? _SelectionBar(
                          key: const ValueKey('selection-bar'),
                          count: _selected.length,
                          onAdd: _addSelectedToList,
                          onCancel: _stopSelecting,
                        )
                      : showRateButton
                          ? _RateButton(
                              key: const ValueKey('rate-button'),
                              onTap: () => _rate(null),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-rate-button')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Nombre del artista; al tocarlo se abre su ficha. Con varios artistas se
/// abre el primero (el principal según Spotify).
class _ArtistLink extends StatelessWidget {
  const _ArtistLink({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final artists = album.artists;
    final text = Text(
      album.artist,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: VText.ui(16, weight: 600, color: artists.isEmpty ? null : c.accent),
    );
    if (artists.isEmpty) return text;
    return GestureDetector(
      key: const ValueKey('album-artist'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openArtist(context, artists.first),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: text,
      ),
    );
  }
}

/// Alto que reserva la lista al final para que el botón no tape nada.
const double _rateButtonClearance = 76;
const int _maxComments = 3;

class _RateButton extends StatelessWidget {
  const _RateButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: c.isDark ? 0.35 : 0.28),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: c.scrim.withValues(alpha: c.isDark ? 0.5 : 0.0),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.album_rounded, size: 20),
        label: const Text('Calificar este disco'),
      ),
    );
  }
}

/// Barra fija abajo mientras se eligen canciones: cuántas van, agregar y
/// cancelar.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    super.key,
    required this.count,
    required this.onAdd,
    required this.onCancel,
  });

  final int count;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: c.scrim.withValues(alpha: c.isDark ? 0.5 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('cancel-select'),
            tooltip: 'Cancelar',
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: c.text2),
          ),
          Expanded(
            child: Text(
              count == 0
                  ? 'Elige canciones'
                  : '$count ${count == 1 ? 'canción' : 'canciones'}',
              key: const ValueKey('selection-count'),
              style: VText.ui(14, weight: 700),
            ),
          ),
          FilledButton(
            key: const ValueKey('add-selected'),
            onPressed: count == 0 ? null : onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Agregar a lista'),
          ),
        ],
      ),
    );
  }
}

/// Ya calificado: una sola fila, "Tu nota 8 ·········· Editar".
class _MyRatingRow extends StatelessWidget {
  const _MyRatingRow({required this.entry, required this.onEdit});

  final RatingEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = c.score(entry.score);
    return Container(
      key: ValueKey('rated-${entry.score}'),
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
          ScoreNumeral(score: entry.score, size: 30),
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
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic);
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
              Text('CALIFICACIÓN', style: VText.label(11, color: c.text3)),
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
  const _TrackRow({
    super.key,
    required this.track,
    required this.albumArtist,
    this.selected,
    this.onToggle,
    this.onLongPress,
  });

  final Track track;
  final String albumArtist;

  /// Null cuando no se están eligiendo canciones; si no, si esta va.
  final bool? selected;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final showArtists = track.artists.isNotEmpty && track.artists != albumArtist;
    final selecting = selected != null;
    return InkWell(
      onTap: selecting ? onToggle : null,
      onLongPress: onLongPress,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: selecting
                ? Icon(
                    selected!
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: selected! ? c.accent : c.text3,
                  )
                : Text(
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
      ),
    );
  }
}
