import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/music_list.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/list_mosaic.dart';
import '../widgets/misc.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import 'add_to_list_sheet.dart';
import 'list_form_sheet.dart';
import 'routes.dart';

/// Una lista o ranking: mosaico, nombre, descripción, tipo, autor y sus
/// elementos. Quien la creó reordena (arrastrando), quita, edita y borra;
/// las demás personas la ven en modo lectura y pueden darle "me gusta" o
/// guardarla.
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
  Color? _glow;
  String? _glowFor;
  bool _editing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = ServicesScope.of(context);
    _stream = _services!.lists.watch(widget.listId);
    final initial = widget.initial;
    if (initial != null) _loadGlow(initial);
  }

  Future<void> _loadGlow(MusicList list) async {
    final first = list.covers.isEmpty ? null : list.covers.first;
    if (first == null || first == _glowFor) return;
    _glowFor = first;
    final color = await _services!.palette.dominant(first);
    if (color != null && mounted && _glowFor == first) setState(() => _glow = color);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _reorder(MusicList list, int oldIndex, int newIndex) async {
    final next = reorder(list.items, oldIndex, newIndex);
    if (identical(next, list.items)) return;
    HapticFeedback.selectionClick();
    try {
      await _services!.lists.setItems(list.id, next);
    } catch (e) {
      _snack('No se pudo reordenar: $e');
    }
  }

  Future<void> _remove(MusicList list, ListItem item) async {
    HapticFeedback.lightImpact();
    try {
      await _services!.lists.setItems(list.id, removeItem(list.items, item.id));
    } catch (e) {
      _snack('No se pudo quitar: $e');
    }
  }

  Future<void> _add(MusicList list) async {
    final added = await showAddToList(context, list);
    if (added > 0) _snack('Se agregaron ${list.itemType.count(added)}');
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
      _snack('No se pudo guardar: $e');
    }
  }

  Future<void> _delete(MusicList list) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = VColors.of(ctx);
        return AlertDialog(
          title: Text('¿Borrar "${list.name}"?', style: VText.display(28)),
          content: Text(
            'No se puede deshacer. Quien la haya guardado dejará de verla.',
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const ValueKey('list-delete-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Borrar lista',
                style: VText.ui(14, weight: 700, color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await _services!.lists.delete(list.id);
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      _snack('No se pudo borrar: $e');
    }
  }

  Future<void> _ownerMenu(MusicList list) {
    return showVSheet<void>(
      context,
      (ctx) => SheetScaffold(
        title: list.name,
        subtitle: list.typeLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetAction(
              key: const ValueKey('list-menu-edit'),
              icon: Icons.edit_rounded,
              label: 'Editar nombre y descripción',
              onTap: () {
                Navigator.of(ctx).pop();
                _editMeta(list);
              },
            ),
            const SizedBox(height: 10),
            SheetAction(
              key: const ValueKey('list-menu-add'),
              icon: Icons.add_rounded,
              label: 'Agregar ${list.itemType.label.toLowerCase()}',
              hint: 'Busca un disco y elige',
              onTap: () {
                Navigator.of(ctx).pop();
                _add(list);
              },
            ),
            const SizedBox(height: 10),
            SheetAction(
              key: const ValueKey('list-menu-delete'),
              icon: Icons.delete_outline_rounded,
              label: 'Borrar lista',
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
    final me = CurrentUser.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: StreamBuilder<MusicList?>(
        stream: _stream,
        initialData: widget.initial,
        builder: (context, snap) {
          final list = snap.data;
          if (snap.connectionState == ConnectionState.waiting && list == null) {
            return Stack(
              children: [
                const Center(child: CircularProgressIndicator()),
                _back(topPad),
              ],
            );
          }
          if (list == null) {
            return Stack(
              children: [
                const Center(
                  child: EmptyState(
                    title: 'Esta lista ya no existe',
                    message: 'Su autor la borró.',
                  ),
                ),
                _back(topPad),
              ],
            );
          }
          _loadGlow(list);
          final mine = list.isMine(me.uid);
          return Stack(
            children: [
              _body(context, c, me, list, mine),
              _back(topPad),
              if (mine)
                Positioned(
                  top: topPad + 8,
                  right: 16,
                  child: GlassIconButton(
                    key: const ValueKey('list-menu'),
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _ownerMenu(list),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _back(double topPad) => Positioned(
        top: topPad + 8,
        left: 16,
        child: GlassIconButton(
          key: const ValueKey('back'),
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      );

  Widget _body(
    BuildContext context,
    ViniloPalette c,
    UserProfile me,
    MusicList list,
    bool mine,
  ) {
    final glow = _glow ?? c.surface3;
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final mosaicSize = math.min(size.width * 0.56, 260.0);
    final items = list.items;

    Widget row(int i) {
      final item = items[i];
      final tile = _ItemRow(
        key: ValueKey('list-item-${item.id}'),
        item: item,
        index: i,
        position: list.isRanking ? i + 1 : null,
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
              Padding(
                padding: EdgeInsets.only(top: topPad + 66),
                child: Column(
                  children: [
                    Center(
                      child: ListMosaic(
                        covers: list.covers,
                        size: mosaicSize,
                        radius: 20,
                        shadow: true,
                        shadowColor: glow,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          Text(
                            list.name,
                            key: const ValueKey('list-title'),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: VText.display(34, height: 1.02),
                          ),
                          if (list.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              list.description,
                              key: const ValueKey('list-description-text'),
                              textAlign: TextAlign.center,
                              style: VText.ui(14, color: c.text2, height: 1.4),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '${list.typeLabel} · ${list.itemType.count(list.count)}',
                            key: const ValueKey('list-meta'),
                            textAlign: TextAlign.center,
                            style: VText.ui(13, color: c.text3),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            key: const ValueKey('list-owner'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => openUser(context, list.ownerUid),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UserAvatar(
                                  name: list.owner.name,
                                  color: Color(list.owner.colorValue),
                                  url: list.owner.avatarUrl,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  mine ? 'Tu lista' : 'por ${list.owner.name}',
                                  style: VText.ui(13, weight: 700),
                                ),
                                if (list.owner.username != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    list.owner.handle,
                                    style: VText.ui(13, color: c.text2),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06),
                    const SizedBox(height: 18),
                    _Actions(
                      list: list,
                      me: me,
                      mine: mine,
                      editing: _editing,
                      onAdd: () => _add(list),
                      onToggleEdit: () => setState(() => _editing = !_editing),
                    ),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              title: mine ? 'Tu lista está vacía' : 'Todavía no tiene nada',
              message: mine
                  ? 'Busca un disco y elige ${list.itemType == ListItemType.tracks ? 'sus canciones' : 'agregarlo'}. También puedes hacerlo desde la pantalla de cualquier disco.'
                  : 'Cuando ${list.owner.name} agregue algo, aparecerá aquí.',
              action: mine
                  ? FilledButton.icon(
                      key: const ValueKey('list-add-empty'),
                      onPressed: () => _add(list),
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Agregar ${list.itemType.label.toLowerCase()}'),
                    )
                  : null,
            ),
          )
        else if (mine)
          SliverReorderableList(
            itemCount: items.length,
            onReorder: (o, n) => _reorder(list, o, n),
            proxyDecorator: (child, _, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Material(
                color: c.surface2,
                elevation: 8 * animation.value,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
            ),
            itemBuilder: (context, i) => row(i),
          )
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) =>
                row(i).animate().fadeIn(delay: (25 * (i % 12)).ms, duration: 300.ms),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, bottomPad + 30),
            child: Text(
              mine && items.isNotEmpty
                  ? 'Mantén pulsado un elemento para moverlo. En "Editar" puedes quitar.'
                  : 'Datos y portadas de Spotify',
              style: VText.ui(11, color: c.text3, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Píldoras de acción bajo el encabezado: para la dueña, agregar y editar;
/// para las demás personas, "me gusta" y guardar. El número de likes se ve
/// siempre.
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
    final services = ServicesScope.of(context);
    final liked = list.likedByMe(me.uid);
    final saved = list.savedByMe(me.uid);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (mine) ...[
          _ActionPill(
            key: const ValueKey('list-add'),
            icon: Icons.add_rounded,
            label: 'Agregar',
            active: true,
            onTap: onAdd,
          ),
          _ActionPill(
            key: const ValueKey('list-edit-toggle'),
            icon: editing ? Icons.check_rounded : Icons.edit_rounded,
            label: editing ? 'Listo' : 'Editar',
            active: editing,
            onTap: onToggleEdit,
          ),
          if (list.likes > 0)
            _ActionPill(
              key: const ValueKey('list-likes'),
              icon: Icons.favorite_rounded,
              label: '${list.likes}',
              color: c.danger,
              onTap: null,
            ),
        ] else ...[
          _ActionPill(
            key: const ValueKey('list-like'),
            icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: list.likes > 0 ? '${list.likes}' : 'Me gusta',
            active: liked,
            color: c.danger,
            onTap: () {
              HapticFeedback.lightImpact();
              services.lists.toggleLike(list, me);
            },
          ),
          _ActionPill(
            key: const ValueKey('list-save'),
            icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: saved ? 'Guardada' : 'Guardar',
            active: saved,
            onTap: () {
              HapticFeedback.lightImpact();
              services.lists.toggleSave(list, me);
            },
          ),
        ],
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  /// Color del estado activo (por defecto el énfasis).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final tint = color ?? c.accent;
    final fg = active ? tint : c.text;
    return Material(
      color: active ? tint.withValues(alpha: 0.14) : c.surface2,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? tint.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg)
                  .animate(key: ValueKey(active))
                  .scale(
                    begin: const Offset(1.3, 1.3),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(width: 7),
              Text(label, style: VText.ui(14, weight: 700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una canción o un disco de la lista. En rankings lleva su posición; en
/// modo edición, el botón de quitar y el asa para arrastrar.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.position,
    required this.editing,
    required this.reorderable,
    required this.onRemove,
    required this.onTap,
  });

  final ListItem item;
  final int index;
  final int? position;
  final bool editing;
  final bool reorderable;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: editing ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
          child: Row(
            children: [
              if (editing) ...[
                GestureDetector(
                  key: ValueKey('list-remove-$index'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.remove_circle_rounded, color: c.danger, size: 22),
                  ),
                ),
              ],
              if (position != null)
                SizedBox(
                  width: 34,
                  child: Text(
                    '$position',
                    style: VText.display(
                      position! < 100 ? 24 : 18,
                      height: 1,
                      color: position! <= 3 ? c.accent : c.text2,
                    ),
                  ),
                ),
              AlbumCover(url: item.smallCover, size: 52, radius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(15, weight: 700),
                    ),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(12, color: c.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(item.meta, style: VText.ui(13, color: c.text3)),
              if (editing && reorderable)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.drag_handle_rounded, color: c.text3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
