import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/list_row_tile.dart';
import '../widgets/misc.dart';
import '../widgets/sheet.dart';
import 'list_form_sheet.dart';

/// Elegir una de mis listas del tipo pedido, o crear una nueva ahí mismo.
/// Devuelve la lista elegida (o recién creada), o null si se cierra.
Future<MusicList?> showListPicker(
  BuildContext context, {
  required ListItemType itemType,
  String? excludeListId,
}) {
  return showVSheet<MusicList>(
    context,
    (_) => _ListPicker(itemType: itemType, excludeListId: excludeListId),
  );
}

class _ListPicker extends StatefulWidget {
  const _ListPicker({required this.itemType, required this.excludeListId});

  final ListItemType itemType;
  final String? excludeListId;

  @override
  State<_ListPicker> createState() => _ListPickerState();
}

class _ListPickerState extends State<_ListPicker> {
  Stream<List<MusicList>>? _lists;
  bool _creating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lists != null) return;
    final me = CurrentUser.of(context);
    _lists = ServicesScope.of(context).lists.ownedBy(me.uid);
  }

  Future<void> _create() async {
    final draft = await showListForm(context, fixedItemType: widget.itemType);
    if (draft == null || !mounted) return;
    setState(() => _creating = true);
    try {
      final services = ServicesScope.of(context);
      final me = CurrentUser.of(context);
      final list = await services.lists.create(
        owner: me,
        name: draft.name,
        description: draft.description,
        kind: draft.kind,
        itemType: widget.itemType,
      );
      if (mounted) Navigator.of(context).pop(list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.listCreateFailed(describeError(e, context.l10n)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return SheetScaffold(
      title: context.l10n.pickerTitle,
      subtitle: widget.itemType == ListItemType.tracks
          ? context.l10n.pickerSubtitleTracks
          : context.l10n.pickerSubtitleAlbums,
      height: 0.8,
      scrollable: false,
      child: StreamBuilder<List<MusicList>>(
        stream: _lists,
        builder: (context, snap) {
          final lists = (snap.data ?? const <MusicList>[])
              .where((l) => l.itemType == widget.itemType && l.id != widget.excludeListId)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              Material(
                color: c.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const ValueKey('picker-new-list'),
                  onTap: _creating ? null : _create,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: c.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _creating
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.onAccent,
                                  ),
                                )
                              : Icon(Icons.add_rounded, color: c.onAccent),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.listNew,
                          style: VText.ui(15, weight: 700, color: c.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!snap.hasData)
                for (var i = 0; i < 3; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Skeleton(height: 70, radius: 18),
                  )
              else if (lists.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 0),
                  child: Text(
                    widget.itemType == ListItemType.tracks
                        ? context.l10n.pickerEmptyTracks
                        : context.l10n.pickerEmptyAlbums,
                    textAlign: TextAlign.center,
                    style: VText.ui(14, color: c.text3, height: 1.4),
                  ),
                )
              else
                for (final (i, list) in lists.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListRowTile(
                      key: ValueKey('picker-list-$i'),
                      list: list,
                      onTap: () => Navigator.of(context).pop(list),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
