import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/share_links.dart';
import '../widgets/album_cover.dart';
import '../widgets/photo_picker.dart';
import '../widgets/pull_stretch.dart';
import '../share_cards/share_specs.dart';
import '../widgets/share_button.dart';
import '../widgets/share_sheet.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'add_to_list_sheet.dart';
import 'list_form_sheet.dart';
import 'routes.dart';

/// Alto de la franja de color debajo de la barra de estado (300 en el
/// prototipo, con sus 54 de barra de estado).
const double _stripeBelowStatus = 246;

/// Una lista o un ranking: una franja del color de su portada con volver,
/// compartir y ···; la portada de 150 con "Lista · 12 canciones"; el título;
/// "Tu lista @usuario"; "+ Agregar" y "Editar" (o, en la de otra persona,
/// "♥ Me gusta" y "Guardar"); y sus elementos. En un ranking, los tres
/// primeros llevan el número grande en el tono de la portada. Quien la creó
/// reordena (mantener pulsado, o con el asa en "Editar"), quita con
/// "Deshacer", edita y borra.
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.listId, this.initial});

  final String listId;
  final MusicList? initial;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  Services? _services;
  Stream<MusicList?>? _stream;

  /// El color dominante de la portada de la lista (la franja y los números
  /// del ranking); null mientras no se sabe.
  Color? _coverColor;
  String? _coverFor;
  bool _editing = false;

  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);

  // Orden optimista: al soltar (o quitar) un elemento la lista se pinta ya
  // con el cambio, sin esperar a que vuelva el documento; así no salta un
  // cuadro al orden viejo. Se descarta en cuanto llega cualquier versión
  // nueva del documento (la propia escritura o un error que la revierte).
  MusicList? _raw;
  List<ListItem>? _optimistic;
  MusicList? _optimisticBase;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // La barra fija aparece cuando la franja pasa por debajo de ella.
      _collapsed.value = _scroll.offset > _stripeBelowStatus - 54;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = ServicesScope.of(context);
    _stream = _services!.lists.watch(widget.listId);
    final initial = widget.initial;
    if (initial != null) _loadCoverColor(initial);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  /// El color sale de la portada elegida o, sin ella, de la del primer
  /// elemento.
  void _loadCoverColor(MusicList list) {
    final url = list.coverUrl ?? (list.covers.isEmpty ? null : list.covers.first);
    if (url == null || url == _coverFor) return;
    _coverFor = url;
    final known = _services!.palette.cached(url);
    if (known != null) {
      _coverColor = known;
      return;
    }
    _services!.palette.dominant(url).then((color) {
      if (color != null && mounted && _coverFor == url) setState(() => _coverColor = color);
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _reorder(MusicList list, int oldIndex, int newIndex) async {
    final next = reorder(list.items, oldIndex, newIndex);
    if (_sameOrder(next, list.items)) return;
    HapticFeedback.selectionClick();
    await _write(list, next, context.l10n.listReorderFailed);
  }

  Future<void> _remove(MusicList list, ListItem item) async {
    HapticFeedback.lightImpact();
    final index = list.items.indexWhere((i) => i.id == item.id);
    await _write(list, removeItem(list.items, item.id), context.l10n.listRemoveFailed);
    if (!mounted || index < 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.listRemoved(item.name)),
          duration: const Duration(seconds: 4),
          // Con acción, Flutter lo dejaría fijo hasta cerrarlo a mano.
          persist: false,
          action: SnackBarAction(
            key: const ValueKey('list-undo'),
            label: context.l10n.undo,
            onPressed: () {
              // Vuelve a su posición sobre la lista tal como esté ahora.
              final current = _raw;
              if (current == null || !mounted) return;
              final shown = _optimistic ?? current.items;
              _write(current, insertItemAt(shown, item, index), context.l10n.undoFailed);
            },
          ),
        ),
      );
  }

  Future<void> _write(MusicList list, List<ListItem> next, String error) async {
    setState(() {
      _optimistic = next;
      _optimisticBase = _raw;
    });
    try {
      await _services!.lists.setItems(list.id, next);
    } catch (e) {
      if (mounted) setState(() => _optimistic = null);
      if (mounted) _snack('$error: ${describeError(e, context.l10n)}');
    }
  }

  static bool _sameOrder(List<ListItem> a, List<ListItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _add(MusicList list) async {
    final added = await showAddToList(context, list);
    if (added > 0 && mounted) _snack(list.itemType.added(added, context.l10n));
  }

  Future<void> _editMeta(MusicList list) async {
    final draft = await showListForm(context, initial: list);
    if (draft == null) return;
    try {
      await _services!.lists.updateMeta(
        list.id,
        name: draft.name,
        description: draft.description,
      );
    } catch (e) {
      if (mounted) _snack(context.l10n.couldNotSave(describeError(e, context.l10n)));
    }
  }

  Future<void> _delete(MusicList list) async {
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.listDeleteTitle(list.name),
      message: l.listDeleteBody,
      confirmLabel: l.listDelete,
      danger: true,
      confirmKey: const ValueKey('list-delete-confirm'),
    );
    if (!ok || !mounted) return;
    try {
      await _services!.lists.delete(list);
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) _snack(context.l10n.deleteFailed(describeError(e, context.l10n)));
    }
  }

  Future<void> _changeCover(MusicList list) async {
    final pick = await pickPhoto(
      context,
      aspectRatio: 1,
      outputWidth: 1000,
      title: context.l10n.listCoverTitle,
    );
    final bytes = pick?.bytes;
    if (bytes == null || !mounted) return;
    _snack(context.l10n.listCoverUploading);
    try {
      await _services!.lists.setCover(list, bytes);
      _coverFor = null;
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (mounted) _snack(context.l10n.listCoverFailed(describeError(e, context.l10n)));
    }
  }

  Future<void> _removeCover(MusicList list) async {
    try {
      await _services!.lists.removeCover(list);
      _coverFor = null;
    } catch (e) {
      if (mounted) _snack(context.l10n.listCoverRemoveFailed(describeError(e, context.l10n)));
    }
  }

  Future<void> _ownerMenu(MusicList list) {
    final l = context.l10n;
    return showVSheet<void>(
      context,
      (ctx) => SheetScaffold(
        title: list.name,
        subtitle: list.typeLabel(l),
        titleSize: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetAction(
              key: const ValueKey('list-menu-edit'),
              vicon: VIcon.pencil,
              label: l.listMenuEdit,
              onTap: () {
                Navigator.of(ctx).pop();
                _editMeta(list);
              },
            ),
            SheetAction(
              key: const ValueKey('list-menu-add'),
              vicon: VIcon.plus,
              label: list.itemType.addLabel(l),
              hint: l.listMenuAddHint,
              onTap: () {
                Navigator.of(ctx).pop();
                _add(list);
              },
            ),
            SheetAction(
              key: const ValueKey('list-menu-cover'),
              vicon: VIcon.image,
              label: list.coverUrl == null ? l.listCoverChoose : l.listCoverChange,
              hint: l.listCoverHint,
              onTap: () {
                Navigator.of(ctx).pop();
                _changeCover(list);
              },
            ),
            if (list.coverUrl != null)
              SheetAction(
                key: const ValueKey('list-menu-cover-remove'),
                vicon: VIcon.close,
                label: l.listCoverRemove,
                hint: l.listCoverRemoveHint,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removeCover(list);
                },
              ),
            SheetAction(
              key: const ValueKey('list-menu-delete'),
              vicon: VIcon.trash,
              label: l.listDelete,
              danger: true,
              onTap: () {
                Navigator.of(ctx).pop();
                _delete(list);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final me = CurrentUser.of(context);
    return Scaffold(
      body: StreamBuilder<MusicList?>(
        stream: _stream,
        initialData: widget.initial,
        builder: (context, snap) {
          final raw = snap.data;
          _raw = raw;
          if (_optimistic != null && !identical(raw, _optimisticBase)) {
            _optimistic = null;
            _optimisticBase = null;
          }
          final optimistic = _optimistic;
          final list = raw == null || optimistic == null ? raw : raw.copyWith(items: optimistic);
          if (list == null) {
            final waiting = snap.connectionState == ConnectionState.waiting;
            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: VIconButton(
                        key: const ValueKey('back'),
                        icon: VIcon.back,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  if (waiting)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(VSpace.page, 28, VSpace.page, 0),
                      child: VSkeleton(width: 150, height: 150),
                    )
                  else
                    VEmptyState(
                      title: l.listGone,
                      message: l.listGoneBody,
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 28, VSpace.page, 24),
                    ),
                ],
              ),
            );
          }
          _loadCoverColor(list);
          final mine = list.isMine(me.uid);
          ShareMessage share(AppLocalizations l) => shareListMessage(list, l, mine: mine);
          List<ShareCardSpec> shareCards() => list.items.isEmpty
              ? const []
              : ShareSpecs.list(list, accent: ShareSpecs.accentOf(context));
          return Stack(
            children: [
              _body(context, c, me, list, mine, share, shareCards),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _collapsed,
                  builder: (context, collapsed, _) => collapsed
                      ? _StickyBar(
                          key: const ValueKey('list-bar'),
                          title: list.name,
                          share: share,
                          shareCards: shareCards,
                          onMenu: mine ? () => _ownerMenu(list) : null,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ViniloPalette c,
    UserProfile me,
    MusicList list,
    bool mine,
    ShareMessage Function(AppLocalizations l) share,
    List<ShareCardSpec> Function() shareCards,
  ) {
    final l = context.l10n;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final cover = _coverColor;
    final stripe = cover == null ? c.surface : c.coverShade(cover);
    final tone = cover == null ? c.accentText : c.coverTone(cover);
    final items = list.items;
    final first = items.isEmpty ? null : items.first;
    final bigCover = list.coverUrl ?? first?.cover ?? first?.smallCover;
    final veil = c.bg.withValues(alpha: 0.45);

    Widget row(int i) {
      final item = items[i];
      final tile = _ItemRow(
        key: ValueKey('list-item-${item.id}'),
        item: item,
        index: i,
        ranking: list.isRanking,
        tone: tone,
        editing: mine && _editing,
        reorderable: mine,
        onRemove: () => _remove(list, item),
        onTap: () => openAlbum(
          context,
          item.album,
          heroTag: 'list-${list.id}-${item.id}-$i',
        ),
      );
      if (!mine) return tile;
      // Quien creó la lista arrastra manteniendo pulsado (o con el asa en
      // modo edición).
      return ReorderableDelayedDragStartListener(
        key: ValueKey('drag-${item.id}'),
        index: i,
        child: tile,
      );
    }

    return CustomScrollView(
      controller: _scroll,
      // Rebota arriba: al tirar hacia abajo la franja crece.
      physics: pullPhysics,
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topPad + _stripeBelowStatus,
                child: PullStretch(
                  controller: _scroll,
                  height: topPad + _stripeBelowStatus,
                  child: ColoredBox(color: stripe),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PullPinned(
                    controller: _scroll,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, topPad + 4, 16, 0),
                      child: Row(
                        children: [
                          VIconButton(
                            key: const ValueKey('back'),
                            icon: VIcon.back,
                            style: VIconButtonStyle.filled,
                            fill: veil,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          ShareButton(key: const ValueKey('share-list'), message: share, cards: shareCards, fill: veil),
                          if (mine) ...[
                            const SizedBox(width: 4),
                            VIconButton(
                              key: const ValueKey('list-menu'),
                              icon: VIcon.more,
                              style: VIconButtonStyle.filled,
                              fill: veil,
                              onTap: () => _ownerMenu(list),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 20, VSpace.page, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AlbumCover(url: bigCover, size: 150),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            key: const ValueKey('list-meta'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VMono(list.kind.label(l), color: c.inkA(0.7)),
                              const SizedBox(height: 4),
                              Text(
                                '${list.count}',
                                style: VText.display(44, weight: 700, height: 0.85, tracking: 0),
                              ),
                              VMono(
                                list.itemType == ListItemType.tracks
                                    ? l.listTracksWord(list.count)
                                    : l.listAlbumsWord(list.count),
                                color: c.inkA(0.7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          list.name,
                          key: const ValueKey('list-title'),
                          style: VText.display(
                            list.name.characters.length > 22 ? 40 : 52,
                            weight: 800,
                            height: 0.9,
                            tracking: 0,
                          ),
                        ),
                        if (list.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            list.description,
                            key: const ValueKey('list-description-text'),
                            style: VText.ui(14, color: c.ink2, height: 1.4),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _Owner(list: list, mine: mine),
                        const SizedBox(height: 16),
                        _Actions(
                          list: list,
                          me: me,
                          mine: mine,
                          editing: _editing,
                          onAdd: () => _add(list),
                          onToggleEdit: () => setState(() => _editing = !_editing),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: VEmptyState(
                title: mine ? l.listEmptyMineTitle : l.listEmptyTheirsTitle,
                message: mine
                    ? (list.itemType == ListItemType.tracks ? l.listEmptyMineTracks : l.listEmptyMineAlbums)
                    : l.listEmptyTheirs(list.owner.name),
                action: mine
                    ? VPrimaryButton.accent(
                        key: const ValueKey('list-add-empty'),
                        label: list.itemType.addLabel(l),
                        onPressed: () => _add(list),
                      )
                    : null,
              ),
            ),
          )
        else if (mine)
          SliverReorderableList(
            itemCount: items.length,
            onReorder: (o, n) => _reorder(list, o, n),
            proxyDecorator: (child, _, _) => ColoredBox(color: c.sheet, child: child),
            itemBuilder: (context, i) => row(i),
          )
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => row(i),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, bottomPad + 30),
            child: Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: VMono(
                mine && items.isNotEmpty ? l.listFooterOwner : l.spotifyCredit,
                size: 10,
                tracking: 0.04,
                height: 1.8,
                color: c.ink4,
                uppercase: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Tu lista @usuario" (o el nombre de quien la hizo), con su avatar de 22.
class _Owner extends StatelessWidget {
  const _Owner({required this.list, required this.mine});

  final MusicList list;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final owner = list.owner;
    return Pressable(
      key: const ValueKey('list-owner'),
      onTap: () => openUser(context, list.ownerUid),
      builder: (context, pressed) => Opacity(
        opacity: pressed ? 0.6 : 1,
        child: Row(
          children: [
            UserAvatar(
              name: owner.name,
              color: Color(owner.colorValue),
              url: owner.avatarUrl,
              size: 22,
              initialSize: 11,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mine ? context.l10n.listYours : owner.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VText.ui(13.5, weight: 700),
              ),
            ),
            if (owner.username != null) ...[
              const SizedBox(width: 8),
              Text(owner.handle, style: VText.ui(13.5, color: c.ink3)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Los dos botones bajo el título: para la autora, "+ Agregar" (tinta) y
/// "Editar" (con borde); para las demás personas, "♥ Me gusta · N" y
/// "Guardar" (o "Guardada").
class _Actions extends StatelessWidget {
  const _Actions({
    required this.list,
    required this.me,
    required this.mine,
    required this.editing,
    required this.onAdd,
    required this.onToggleEdit,
  });

  final MusicList list;
  final UserProfile me;
  final bool mine;
  final bool editing;
  final VoidCallback onAdd;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final services = ServicesScope.of(context);
    final Widget first;
    final Widget second;
    if (mine) {
      first = VPrimaryButton(
        key: const ValueKey('list-add'),
        label: l.listAddPlus,
        center: true,
        height: 44,
        fontSize: 14,
        onPressed: onAdd,
      );
      second = VSecondaryButton(
        key: const ValueKey('list-edit-toggle'),
        label: editing ? l.done : l.edit,
        center: true,
        height: 44,
        fontSize: 14,
        color: editing ? c.accentText : null,
        borderColor: editing ? c.accentText : null,
        onPressed: onToggleEdit,
      );
    } else {
      final liked = list.likedByMe(me.uid);
      final saved = list.savedByMe(me.uid);
      final likeLabel = list.likes > 0 ? '${l.like} · ${list.likes}' : l.like;
      final heart = VIconView(
        liked ? VIcon.heartFilled : VIcon.heart,
        size: 12,
        color: liked ? c.onAccent : c.bg,
      );
      void toggleLike() {
        HapticFeedback.lightImpact();
        services.lists.toggleLike(list, me);
      }

      first = liked
          ? VPrimaryButton.accent(
              key: const ValueKey('list-like'),
              label: likeLabel,
              leading: heart,
              center: true,
              height: 44,
              fontSize: 14,
              onPressed: toggleLike,
            )
          : VPrimaryButton(
              key: const ValueKey('list-like'),
              label: likeLabel,
              leading: heart,
              center: true,
              height: 44,
              fontSize: 14,
              onPressed: toggleLike,
            );
      second = VSecondaryButton(
        key: const ValueKey('list-save'),
        label: saved ? l.saved : l.save,
        leading: saved ? VIconView(VIcon.check, size: 12, color: c.accentText) : null,
        center: true,
        height: 44,
        fontSize: 14,
        color: saved ? c.accentText : null,
        borderColor: saved ? c.accentText : null,
        onPressed: () {
          HapticFeedback.lightImpact();
          services.lists.toggleSave(list, me);
        },
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ],
    );
  }
}

/// Un elemento. En una lista: portada de 44, título, artista y duración (o
/// año). En un ranking: su posición (60 el primero, 40 el segundo y el
/// tercero, en el tono de la portada; 28 y apagada del cuarto en adelante),
/// título y artista. En modo edición, quitar (×) y el asa para arrastrar.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.ranking,
    required this.tone,
    required this.editing,
    required this.reorderable,
    required this.onRemove,
    required this.onTap,
  });

  final ListItem item;
  final int index;
  final bool ranking;
  final Color tone;
  final bool editing;
  final bool reorderable;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final position = index + 1;
    final top = ranking && position == 1;
    final number = !ranking
        ? null
        : Text(
            '$position',
            maxLines: 1,
            softWrap: false,
            style: VText.display(
              position == 1 ? 60 : (position <= 3 ? 40 : 28),
              weight: position == 1 ? 800 : 700,
              height: 0.8,
              tracking: 0,
              color: position <= 3 ? tone : c.ink4,
            ),
          );
    final Widget trailing = editing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pressable(
                key: ValueKey('list-remove-$index'),
                onTap: onRemove,
                builder: (context, pressed) => Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: pressed ? c.danger : c.lineStrong)),
                  child: VIconView(VIcon.close, size: 12, color: c.danger),
                ),
              ),
              if (reorderable)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: VIconView(VIcon.drag, size: 18, color: c.ink3),
                  ),
                ),
            ],
          )
        : Text(item.meta, style: VText.mono(12, tracking: 0, color: c.ink3));

    return Pressable(
      onTap: editing ? null : onTap,
      builder: (context, pressed) => Container(
        padding: EdgeInsets.symmetric(horizontal: VSpace.page, vertical: top ? 12 : 10),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : c.bg,
          border: Border(top: BorderSide(color: index == 0 ? c.line : c.lineSoft)),
        ),
        child: Row(
          children: [
            if (ranking)
              SizedBox(width: 52, child: number)
            else
              AlbumCover(url: item.smallCover, size: 44),
            SizedBox(width: ranking ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: top ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: top
                        ? VText.display(24, weight: 700, stretch: 75, height: 1, tracking: 0)
                        : VText.ui(15, weight: 600),
                  ),
                  SizedBox(height: top ? 3 : 0),
                  Text(
                    item.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12.5, color: c.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// La barra que queda arriba al pasar la franja: volver, el nombre de la
/// lista, compartir y ···, con una línea debajo.
class _StickyBar extends StatelessWidget {
  const _StickyBar({
    super.key,
    required this.title,
    required this.share,
    required this.shareCards,
    required this.onMenu,
  });

  final String title;
  final ShareMessage Function(AppLocalizations l) share;
  final List<ShareCardSpec> Function() shareCards;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 4, 16, 10),
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VText.ui(14, weight: 600),
            ),
          ),
          const SizedBox(width: 10),
          ShareButton(message: share, cards: shareCards, style: VIconButtonStyle.bordered),
          if (onMenu != null) ...[
            const SizedBox(width: 4),
            VIconButton(icon: VIcon.more, onTap: onMenu),
          ],
        ],
      ),
    );
  }
}
