import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/oklch.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/ranking.dart';
import '../util/share_links.dart';
import '../util/streams.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_strip.dart';
import '../widgets/comment_card.dart';
import '../widgets/rating_sheet.dart';
import '../widgets/share_button.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_ruler.dart';
import '../widgets/v_sections.dart';
import 'list_form_sheet.dart';
import 'list_picker_sheet.dart';
import 'routes.dart';

/// Cuántos comentarios se muestran en "Comentarios destacados".
const int _featuredComments = 2;

/// El disco: la portada a todo el ancho con volver, compartir y listas
/// encima; la meta, el título y el artista; "Tu nota" y "Comunidad" con el
/// histograma y, debajo, el botón para calificar o la regla para cambiar la
/// nota; las canciones; "Calificado por"; "Comentarios destacados"; "Más
/// de…" y el pie. Al pasar la portada aparece una barra fija arriba.
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
  Future<AlbumPage>? _more;
  Stream<AlbumStats?>? _stats;
  Stream<RatingEntry?>? _mine;
  Stream<List<RatingEntry>>? _community;

  /// "Calificado por": las notas de las personas que sigo sobre este disco.
  Stream<List<RatingEntry>>? _friends;

  /// El color dominante de la portada (null mientras no se sabe o si no se
  /// pudo sacar: entonces se usa el énfasis).
  Color? _coverColor;

  final ScrollController _scroll = ScrollController();

  /// Si ya se pasó la portada: entonces se ve la barra fija de arriba.
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);

  /// Desde qué desplazamiento se ve la barra: cuando el borde de abajo de la
  /// portada pasa por debajo de ella (barra de estado + 4 + 40 + 10). Se
  /// calcula al dibujar.
  double _collapseAt = double.infinity;

  /// Selección de canciones para agregarlas a una lista.
  bool _selecting = false;
  final Set<String> _selected = {};

  /// Nota que se pidió borrar y espera a que se cierre el aviso "Deshacer".
  /// Mientras tanto se muestra como si no hubiera nota, pero sigue en
  /// Firestore. `_deleteToken` cambia al cancelar, para que un aviso viejo
  /// no borre nada.
  RatingEntry? _pendingDelete;
  int _deleteToken = 0;

  /// La nota que se tocó en la regla, mientras Firestore la confirma.
  int? _quickScore;

  Album get _album => _detail ?? widget.album;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

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
    _friends = switchLatest(
      services.follows.followingIds(me.uid).distinct(listEquals),
      (List<String> uids) => services.ratings.friendsRatings(widget.album.id, uids),
    );
    _detail = services.spotify.cachedAlbum(widget.album.id);
    if (_detail == null) {
      _loadDetail();
    } else {
      _loadMore();
    }
    _loadPalette();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  void _onScroll() {
    _collapsed.value = _scroll.offset > _collapseAt;
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
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
    final url = widget.album.smallCover ?? widget.album.bestCover;
    // Si el tono ya se sacó (el disco se vio antes o viene de la ficha del
    // artista), se usa desde el primer cuadro.
    final known = _services!.palette.cached(url);
    if (known != null) {
      _coverColor = known;
      return;
    }
    final color = await _services!.palette.dominant(url);
    if (color != null && mounted) setState(() => _coverColor = color);
  }

  Future<void> _rate(RatingEntry? existing) async {
    // Calificar mientras un borrado espera su "Deshacer" lo cancela: la nota
    // sigue en Firestore y se abre para editarla.
    final pending = _pendingDelete;
    if (pending != null) {
      _cancelPendingDelete();
      existing = pending;
    }
    final result = await showRatingSheet(
      context,
      album: _album,
      existing: existing,
    );
    if (!mounted || result == null) return;
    if (result == RatingSheetResult.deleted) {
      if (existing != null) _deleteWithUndo(existing);
      return;
    }
    setState(() => _quickScore = null);
    _snack(context.l10n.ratingSaved, seconds: 2);
  }

  /// Con nota, tocar otra celda de la regla la cambia al instante (con el
  /// mismo comentario).
  Future<void> _quickRate(RatingEntry mine, int score) async {
    if (score == (_quickScore ?? mine.score)) return;
    HapticFeedback.selectionClick();
    setState(() => _quickScore = score);
    final me = CurrentUser.of(context);
    final l10n = context.l10n;
    try {
      await _services!.ratings.rate(user: me, album: _album, score: score, note: mine.note);
      _snack(l10n.ratingSavedShort, seconds: 2);
    } catch (e) {
      if (!mounted) return;
      setState(() => _quickScore = null);
      _snack(l10n.couldNotSave(describeError(e, l10n)));
    }
  }

  /// Oculta la nota y ofrece "Deshacer" unos segundos. Si el aviso se cierra
  /// sin deshacer, se borra de verdad, aunque ya se haya salido de la
  /// pantalla (por eso se capturan el repositorio y los ids).
  void _deleteWithUndo(RatingEntry entry) {
    final ratings = _services!.ratings;
    final l10n = context.l10n;
    final uid = entry.uid;
    final albumId = entry.albumId;
    final token = ++_deleteToken;
    setState(() {
      _pendingDelete = entry;
      _quickScore = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.ratingDeleted),
        duration: const Duration(seconds: 4),
        // Con acción, Flutter lo dejaría fijo hasta cerrarlo a mano.
        persist: false,
        action: SnackBarAction(
          key: const ValueKey('rating-undo'),
          label: l10n.undo,
          onPressed: () {},
        ),
      ),
    );
    controller.closed.then((reason) async {
      if (token != _deleteToken) return;
      if (reason == SnackBarClosedReason.action) {
        HapticFeedback.lightImpact();
        if (mounted) setState(() => _pendingDelete = null);
        return;
      }
      try {
        await ratings.remove(uid: uid, albumId: albumId);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.ratingDeleteFailed(describeError(e, l10n)))),
        );
      }
      if (mounted && token == _deleteToken) {
        setState(() => _pendingDelete = null);
      }
    });
  }

  void _cancelPendingDelete() {
    _deleteToken++;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _pendingDelete = null);
  }

  void _snack(String text, {MusicList? list, int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: Duration(seconds: seconds),
          // Con acción, Flutter lo deja fijo hasta cerrarlo a mano: que se
          // vaya solo.
          persist: false,
          action: list == null
              ? null
              : SnackBarAction(
                  label: context.l10n.viewList,
                  onPressed: () => openList(context, listId: list.id, initial: list),
                ),
        ),
      );
  }

  /// Hoja con las acciones de listas de este disco. Elegir canciones sueltas
  /// se hace manteniendo pulsada una canción (lo dice el encabezado).
  Future<void> _listActions() {
    final album = _album;
    final hasTracks = _detail != null && _detail!.tracks.isNotEmpty;
    final l10n = context.l10n;
    return showVSheet<void>(
      context,
      (ctx) => SheetScaffold(
        overline: l10n.pickerOverlineAlbum(album.name),
        title: l10n.pickerTitle,
        titleSize: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetAction(
              key: const ValueKey('add-album-to-list'),
              vicon: VIcon.disc,
              label: l10n.albumAddToList,
              hint: l10n.albumAddToListHint,
              onTap: () {
                Navigator.of(ctx).pop();
                _addAlbumToList();
              },
            ),
            SheetAction(
              key: const ValueKey('create-list-from-album'),
              vicon: VIcon.addToList,
              label: l10n.albumCreateList,
              hint: hasTracks ? l10n.albumCreateListHint : l10n.albumWaitTracks,
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
    final album = _album;
    final list = await showListPicker(
      context,
      itemType: ListItemType.albums,
      overline: context.l10n.pickerOverlineAlbum(album.name),
    );
    if (list == null || !mounted) return;
    try {
      final outcome = await _services!.lists.addTo(list.id, [ListItem.fromAlbum(album)]);
      if (!mounted) return;
      _snack('${outcome.message(ListItemType.albums, context.l10n)} · ${list.name}', list: list);
    } catch (e) {
      if (mounted) _snack(context.l10n.addFailed(describeError(e, context.l10n)));
    }
  }

  Future<void> _createListFromAlbum() async {
    final detail = _detail;
    if (detail == null) return;
    final draft = await showListForm(
      context,
      title: context.l10n.albumListFromAlbum,
      initialName: detail.name,
      fixedItemType: ListItemType.tracks,
      submitLabel: context.l10n.listCreate,
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
      if (mounted) _snack(context.l10n.listCreateFailed(describeError(e, context.l10n)));
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
    final chosen = [for (final t in detail.tracks) if (_selected.contains(t.id)) t];
    final l10n = context.l10n;
    final list = await showListPicker(
      context,
      itemType: ListItemType.tracks,
      overline: chosen.length == 1
          ? l10n.pickerOverlineTrack(chosen.first.name)
          : '${l10n.countTracks(chosen.length)} · ${detail.name}',
    );
    if (list == null || !mounted) return;
    final items = [for (final t in chosen) ListItem.fromTrack(t, detail)];
    try {
      final outcome = await _services!.lists.addTo(list.id, items);
      _stopSelecting();
      if (!mounted) return;
      _snack('${outcome.message(ListItemType.tracks, context.l10n)} · ${list.name}', list: list);
    } catch (e) {
      if (mounted) _snack(context.l10n.addFailed(describeError(e, context.l10n)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final album = _album;
    final detail = _detail;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    _collapseAt = MediaQuery.sizeOf(context).width - (topPad + 54);
    // El color de la portada tal cual (las celdas de la regla) y su tono
    // claro (la nota, el artista, el botón); sin color, el énfasis.
    final cover = _coverColor;
    final tone = cover == null ? c.accent : coverTone(cover);
    final fill = cover ?? c.accent;

    return Scaffold(
      body: StreamBuilder<RatingEntry?>(
        stream: _mine,
        builder: (context, mineSnap) {
          final pending = _pendingDelete;
          final mine = pending != null && mineSnap.data?.id == pending.id
              ? null
              : mineSnap.data;
          if (_quickScore != null && mine?.score == _quickScore) {
            // Firestore ya tiene la nota que se tocó.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _quickScore = null);
            });
          }
          final waitingMine = mineSnap.connectionState == ConnectionState.waiting;
          ShareMessage share(AppLocalizations l) => mine != null
              ? shareRatingMessage(mine, l, mine: true)
              : shareAlbumMessage(album, l);

          return Stack(
            children: [
              CustomScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AlbumCover(url: album.bestCover, heroTag: widget.heroTag),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Heading(album: album, detail: detail, tone: tone),
                          const SizedBox(height: 22),
                          StreamBuilder<AlbumStats?>(
                            stream: _stats,
                            builder: (context, statsSnap) => _Scores(
                              stats: statsSnap.data,
                              mine: mine,
                              quickScore: _quickScore,
                              waiting: waitingMine,
                              tone: tone,
                              fill: fill,
                              onRate: () => _rate(mine),
                              onQuickRate: mine == null ? null : (k) => _quickRate(mine, k),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._tracks(c, l10n, detail),
                  // "Calificado por": mis amigos que ya le pusieron nota.
                  StreamBuilder<List<RatingEntry>>(
                    stream: _friends,
                    builder: (context, snap) {
                      final friends = snap.data ?? const <RatingEntry>[];
                      if (friends.isEmpty) {
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      }
                      return SliverToBoxAdapter(
                        child: _RatedBy(friends: friends, tone: tone),
                      );
                    },
                  ),
                  StreamBuilder<List<RatingEntry>>(
                    stream: _community,
                    builder: (context, snap) {
                      final entries = snap.data ?? const <RatingEntry>[];
                      final all = topComments(entries);
                      if (all.isEmpty) {
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      }
                      final shown = all.take(_featuredComments).toList();
                      return SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VBlockTitle(
                              l10n.albumFeaturedComments,
                              subtitle: l10n.albumCommentsShown(shown.length, all.length),
                              action: l10n.seeAllPlural,
                              actionKey: const ValueKey('comments-more'),
                              onAction: () => openComments(context, album: album, initial: entries),
                              padding: const EdgeInsets.fromLTRB(VSpace.page, 34, VSpace.page, 0),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
                              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final (i, entry) in shown.indexed)
                                    CommentCard(
                                      key: ValueKey('comment-$i'),
                                      entry: entry,
                                      index: i,
                                      tone: tone,
                                      last: i == shown.length - 1,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  FutureBuilder<AlbumPage>(
                    future: _more,
                    builder: (context, snap) {
                      final items = (snap.data?.items ?? const <Album>[])
                          .where((a) => a.id != album.id)
                          .toList();
                      final artists = album.artists;
                      if (items.isEmpty || artists.isEmpty) {
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      }
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              VSectionHeader(
                                l10n.moreBy(artists.first.name),
                                action: l10n.albumSeeArtist,
                                actionKey: const ValueKey('more-artist'),
                                onAction: () => openArtist(context, artists.first),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: AlbumStrip(
                                  albums: items,
                                  heroPrefix: 'more-${album.id}',
                                  keyPrefix: 'more',
                                  yearOnly: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: _Footer(
                      album: album,
                      detail: detail,
                      // Con la barra de selección, deja sitio para que las
                      // últimas canciones y el pie no queden tapados.
                      bottom: bottomPad + 30 + (_selecting ? _selectionBarHeight : 0),
                    ),
                  ),
                ],
              ),
              // Volver, compartir y listas sobre la portada o, al pasarla, la
              // barra fija con la portada en miniatura.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _collapsed,
                  builder: (context, collapsed, _) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    child: collapsed
                        ? _StickyBar(
                            key: const ValueKey('album-bar'),
                            album: album,
                            topPad: topPad,
                            share: share,
                            onLists: _listActions,
                            onTitleTap: _scrollToTop,
                          )
                        : Padding(
                            key: const ValueKey('album-buttons'),
                            padding: EdgeInsets.fromLTRB(16, topPad + 4, 16, 0),
                            child: _TopButtons(
                              style: VIconButtonStyle.filled,
                              share: share,
                              onLists: _listActions,
                            ),
                          ),
                  ),
                ),
              ),
              // Barra fija abajo mientras se eligen canciones para una lista.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
                  ),
                  child: _selecting
                      ? _SelectionBar(
                          key: const ValueKey('selection-bar'),
                          count: _selected.length,
                          bottomPad: bottomPad,
                          onAdd: _addSelectedToList,
                          onCancel: _stopSelecting,
                        )
                      : const SizedBox(key: ValueKey('no-selection-bar'), width: double.infinity),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "Canciones · Mantén pulsada para agregar" y sus filas (o lo que se ve
  /// mientras cargan, o el error).
  List<Widget> _tracks(ViniloPalette c, AppLocalizations l10n, AlbumDetail? detail) {
    Widget header({String? action, VoidCallback? onAction}) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 22, VSpace.page, 0),
            child: VSectionHeader(
              l10n.listTypeTracks,
              action: action,
              onAction: onAction,
              accentAction: onAction != null,
              actionKey: onAction == null ? null : const ValueKey('select-all'),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        );

    if (_detailError != null) {
      return [
        header(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 4, VSpace.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.albumDetailError(describeError(_detailError, l10n)),
                  style: VText.ui(13, color: c.danger, height: 1.35),
                ),
                const SizedBox(height: 10),
                VTextLink(
                  l10n.retry,
                  key: const ValueKey('album-retry'),
                  onTap: () {
                    setState(() => _detailError = null);
                    _loadDetail();
                  },
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (detail == null) {
      return [
        header(action: l10n.albumHoldToAdd),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
          sliver: SliverList.builder(
            itemCount: 6,
            itemBuilder: (_, _) => Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineSoft))),
              child: const Row(
                children: [
                  SizedBox(width: 28),
                  Expanded(child: VSkeleton(height: 14)),
                  SizedBox(width: 40),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    if (detail.tracks.isEmpty) return const [];
    final all = _selected.length == detail.tracks.length;
    return [
      _selecting
          ? header(
              action: all ? l10n.selectNone : l10n.filterAll,
              onAction: () => setState(() {
                if (all) {
                  _selected.clear();
                } else {
                  _selected.addAll(detail.tracks.map((t) => t.id));
                }
              }),
            )
          : header(action: l10n.albumHoldToAdd),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        sliver: SliverList.builder(
          itemCount: detail.tracks.length,
          itemBuilder: (_, i) {
            final track = detail.tracks[i];
            return _TrackRow(
              key: ValueKey('track-$i'),
              track: track,
              albumArtist: detail.artist,
              selected: _selecting ? _selected.contains(track.id) : null,
              onToggle: () => _toggleTrack(track.id),
              onLongPress: _selecting ? null : () => _startSelecting(first: track.id),
            );
          },
        ),
      ),
    ];
  }
}

/// Volver a la izquierda; compartir y listas a la derecha, separados 4.
class _TopButtons extends StatelessWidget {
  const _TopButtons({required this.style, required this.share, required this.onLists});

  final VIconButtonStyle style;
  final ShareMessage Function(AppLocalizations l) share;
  final VoidCallback onLists;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        VIconButton(
          key: const ValueKey('back'),
          icon: VIcon.back,
          style: style,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        // Con nota, se comparte la mía; sin nota, el disco.
        ShareButton(key: const ValueKey('share-album'), message: share, style: style),
        const SizedBox(width: 4),
        VIconButton(
          key: const ValueKey('list-actions'),
          icon: VIcon.addToList,
          style: style,
          onTap: onLists,
        ),
      ],
    );
  }
}

/// La barra fija que aparece al pasar la portada: volver, la portada en
/// miniatura con el nombre, compartir y listas, con una línea debajo.
class _StickyBar extends StatelessWidget {
  const _StickyBar({
    super.key,
    required this.album,
    required this.topPad,
    required this.share,
    required this.onLists,
    required this.onTitleTap,
  });

  final Album album;
  final double topPad;
  final ShareMessage Function(AppLocalizations l) share;
  final VoidCallback onLists;

  /// Tocar la portada o el nombre vuelve arriba.
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 4, 16, 10),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          VIconButton(
            key: const ValueKey('back'),
            icon: VIcon.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: Row(
                children: [
                  AlbumCover(url: album.smallCover, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(14, weight: 600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ShareButton(
            key: const ValueKey('share-album'),
            message: share,
            style: VIconButtonStyle.bordered,
          ),
          const SizedBox(width: 4),
          VIconButton(
            key: const ValueKey('list-actions'),
            icon: VIcon.addToList,
            onTap: onLists,
          ),
        ],
      ),
    );
  }
}

/// Debajo de la portada: "Álbum · 1999 · 15 canciones · 1 h 10 min", el
/// título en 64 y "Artista →" en el tono de la portada (abre su ficha).
class _Heading extends StatelessWidget {
  const _Heading({required this.album, required this.detail, required this.tone});

  final Album album;
  final AlbumDetail? detail;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = detail;
    final meta = [
      album.typeLabel(l10n),
      if (album.year != null) '${album.year}',
      if (d != null && d.tracks.isNotEmpty) l10n.countTracks(d.tracks.length)
      else if (album.totalTracks != null) l10n.countTracks(album.totalTracks!),
      if (d != null && d.tracks.isNotEmpty) d.totalDurationLabel,
    ].join(' · ');
    final artists = album.artists;
    final artistText = Text(
      artists.isEmpty ? album.artist : '${album.artist} →',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: VText.ui(17, weight: 500, color: tone),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VMono(meta, key: const ValueKey('album-meta')),
        const SizedBox(height: 10),
        Text(
          album.name,
          key: const ValueKey('album-title'),
          style: VText.display(64, weight: 800, stretch: 65, height: 0.88, tracking: 0),
        ),
        const SizedBox(height: 6),
        if (artists.isEmpty)
          artistText
        else
          Pressable(
            key: const ValueKey('album-artist'),
            // Con varios artistas se abre el primero (el principal según
            // Spotify).
            onTap: () => openArtist(context, artists.first),
            builder: (context, pressed) => Opacity(opacity: pressed ? 0.6 : 1, child: artistText),
          ),
      ],
    );
  }
}

/// "Tu nota" (o "Tu nota · editar" con la nota y su veredicto) y
/// "Comunidad · N notas" con el promedio, el histograma de la comunidad y,
/// debajo, los números con "Calificar este disco" o la regla para cambiar
/// la nota con un toque.
class _Scores extends StatelessWidget {
  const _Scores({
    required this.stats,
    required this.mine,
    required this.quickScore,
    required this.waiting,
    required this.tone,
    required this.fill,
    required this.onRate,
    required this.onQuickRate,
  });

  final AlbumStats? stats;
  final RatingEntry? mine;
  final int? quickScore;
  final bool waiting;
  final Color tone;
  final Color fill;
  final VoidCallback onRate;
  final ValueChanged<int>? onQuickRate;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final s = stats;
    final count = s?.count ?? 0;
    final mineScore = mine == null ? null : (quickScore ?? mine!.score);
    final bigNumber = VText.display(56, weight: 700, height: 0.85, tracking: 0);

    final Widget left;
    if (mineScore == null) {
      left = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VMono(l10n.yourRating),
          const SizedBox(height: 4),
          Text('—', key: const ValueKey('album-unrated'), style: bigNumber.copyWith(color: c.inkA(0.28))),
        ],
      );
    } else {
      left = Pressable(
        key: const ValueKey('rating-edit'),
        onTap: onRate,
        builder: (context, pressed) => Opacity(
          opacity: pressed ? 0.6 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VMono(l10n.albumYourRatingEdit),
              const SizedBox(height: 4),
              Row(
                key: ValueKey('rated-$mineScore'),
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$mineScore', style: bigNumber.copyWith(color: tone)),
                  const SizedBox(width: 10),
                  VMono(Score.label(mineScore, l10n), color: tone),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        VMono(l10n.albumCommunity(count), key: const ValueKey('album-community')),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: count == 0 ? '—' : Score.formatAverage(s!.average, l10n.localeName),
                style: count == 0 ? bigNumber.copyWith(color: c.inkA(0.28)) : null,
              ),
              if (count > 0)
                TextSpan(text: ' /10', style: VText.ui(14, weight: 500, color: c.ink4)),
            ],
          ),
          style: bigNumber,
        ),
      ],
    );

    final Widget below;
    if (waiting) {
      // Mientras llega mi nota, el hueco de los números y el botón.
      below = const SizedBox(key: ValueKey('mine-waiting'), height: 6 + 13 + 16 + 56);
    } else if (mineScore == null) {
      below = Column(
        key: const ValueKey('album-rate'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const RulerNumbers(),
          const SizedBox(height: 16),
          VPrimaryButton.tone(
            key: const ValueKey('rate-button'),
            label: l10n.rateThisAlbum,
            trailing: '1–10 →',
            color: tone,
            onPressed: onRate,
          ),
        ],
      );
    } else {
      below = Column(
        key: const ValueKey('album-ruler'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RulerCells(
            selected: mineScore,
            onTap: onQuickRate,
            selectedColor: tone,
            fill: fill,
            afterNumberColor: c.ink4,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: VMono(l10n.albumTapToChange, size: 10, tracking: 0.06, color: c.ink4)),
              VMono(l10n.albumBarsCommunity, size: 10, tracking: 0.06, color: c.ink4),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Align(alignment: Alignment.bottomLeft, child: left)),
              const SizedBox(width: 12),
              right,
            ],
          ),
          const SizedBox(height: 16),
          // Las barras de la comunidad van en tinta al 35 % (como el
          // prototipo) para no competir con la regla del tono de la portada.
          Histogram10(counts: s?.hist ?? const {}, height: 44, color: c.inkA(0.35)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: below,
          ),
        ],
      ),
    );
  }
}

/// Una canción: número en mono ("01"), título y duración. Mientras se
/// eligen canciones, el número pasa a una casilla; mantener pulsada una
/// empieza a elegir.
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
    return Pressable(
      onTap: selecting ? onToggle : null,
      onLongPress: onLongPress,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(top: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: selecting
                    ? Align(alignment: Alignment.centerLeft, child: _CheckSquare(selected: selected!))
                    : Text(
                        track.number.toString().padLeft(2, '0'),
                        style: VText.mono(11, tracking: 0, color: c.ink4),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.name, style: VText.ui(15)),
                  if (showArtists) ...[
                    const SizedBox(height: 2),
                    Text(
                      track.artists,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(12.5, color: c.ink3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(track.duration, style: VText.mono(12, tracking: 0, color: c.ink3)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Casilla cuadrada de 14: vacía con borde, o llena de énfasis con el check
/// (como la de Lista y Ranking).
class _CheckSquare extends StatelessWidget {
  const _CheckSquare({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? c.accent : null,
        border: selected ? null : Border.all(color: c.lineStrong),
      ),
      child: selected ? VIconView(VIcon.check, size: 9, color: c.onAccent) : null,
    );
  }
}

/// "Calificado por": cuántos amigos, su promedio en el tono de la portada y
/// sus fotos de 56 con la nota debajo. Tocar una foto abre esa calificación.
class _RatedBy extends StatelessWidget {
  const _RatedBy({required this.friends, required this.tone});

  final List<RatingEntry> friends;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final average = friends.fold<int>(0, (sum, e) => sum + e.score) / friends.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VBlockTitle(
          l10n.ratedBy,
          subtitle: l10n.countFriends(friends.length),
          padding: const EdgeInsets.fromLTRB(VSpace.page, 34, VSpace.page, 0),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              VMono(l10n.albumFriendsAverage, size: 10),
              Text(
                Score.formatAverage(average, l10n.localeName),
                key: const ValueKey('friends-average'),
                style: VText.display(34, weight: 700, height: 1, tracking: 0, color: tone),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
          height: 1,
          color: c.line,
        ),
        SizedBox(
          height: 16 + 56 + 8 + 27,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
            itemCount: friends.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, i) {
              final entry = friends[i];
              return Pressable(
                key: ValueKey('friend-rating-$i'),
                onTap: () => openThread(context, ratingId: entry.id, initial: entry),
                builder: (context, pressed) => Opacity(
                  opacity: pressed ? 0.6 : 1,
                  child: Column(
                    children: [
                      UserAvatar(
                        name: entry.user.name,
                        color: entry.user.color,
                        url: entry.user.avatarUrl,
                        size: 56,
                        initialSize: 18,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${entry.score}',
                        style: VText.display(30, weight: 700, height: 0.9, tracking: 0, color: c.accent),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
          child: VMono(l10n.albumTapPhoto, size: 10, tracking: 0.06, color: c.ink4),
        ),
      ],
    );
  }
}

/// El pie: el ℗ de Spotify, la fecha de publicación y el crédito, en mono.
class _Footer extends StatelessWidget {
  const _Footer({required this.album, required this.detail, required this.bottom});

  final Album album;
  final AlbumDetail? detail;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final lines = [
      if (detail?.copyright != null) detail!.copyright!,
      if (album.releaseDate != null) l10n.releasedOn(album.releaseDate!),
      l10n.spotifyCredit,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, bottom),
      child: Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        child: VMono(
          lines.join('\n'),
          key: const ValueKey('album-footer'),
          size: 10,
          tracking: 0.04,
          height: 1.8,
          color: c.ink4,
          uppercase: false,
        ),
      ),
    );
  }
}

/// Alto de la barra de selección sin la zona segura (12 + 44 + 12).
const double _selectionBarHeight = 68;

/// Barra fija abajo mientras se eligen canciones: cancelar, cuántas van y
/// "Agregar a lista".
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    super.key,
    required this.count,
    required this.bottomPad,
    required this.onAdd,
    required this.onCancel,
  });

  final int count;
  final double bottomPad;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    return Container(
      padding: EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 12 + bottomPad),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          VIconButton(
            key: const ValueKey('cancel-select'),
            icon: VIcon.close,
            iconSize: 16,
            tooltip: l10n.cancel,
            onTap: onCancel,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0 ? l10n.addChooseTracks : l10n.countTracks(count),
              key: const ValueKey('selection-count'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VText.ui(15, weight: 600),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 170,
            child: VPrimaryButton.accent(
              key: const ValueKey('add-selected'),
              label: l10n.addToList,
              height: 44,
              fontSize: 15,
              onPressed: count == 0 ? null : onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
