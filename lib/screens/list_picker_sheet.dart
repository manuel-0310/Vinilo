import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/cover_stack.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'list_form_sheet.dart';

/// Elegir una de mis listas del tipo pedido, o crear una nueva ahí mismo.
/// `overline` dice qué se va a agregar ("Canción · Tabú", "Disco ·
/// Bocanada"). Devuelve la lista elegida (o recién creada), o null si se
/// cierra.
Future<MusicList?> showListPicker(
  BuildContext context, {
  required ListItemType itemType,
  String? excludeListId,
  String? overline,
}) {
  return showVSheet<MusicList>(
    context,
    (_) => _ListPicker(
      itemType: itemType,
      excludeListId: excludeListId,
      overline: overline,
    ),
  );
}

class _ListPicker extends StatefulWidget {
  const _ListPicker({
    required this.itemType,
    required this.excludeListId,
    required this.overline,
  });

  final ListItemType itemType;
  final String? excludeListId;
  final String? overline;

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
    final l10n = context.l10n;
    final tracks = widget.itemType == ListItemType.tracks;
    return SheetScaffold(
      overline: widget.overline,
      title: l10n.pickerTitle,
      subtitle: tracks ? l10n.pickerSubtitleTracks : l10n.pickerSubtitleAlbums,
      child: StreamBuilder<List<MusicList>>(
        stream: _lists,
        builder: (context, snap) {
          final lists = (snap.data ?? const <MusicList>[])
              .where((l) => l.itemType == widget.itemType && l.id != widget.excludeListId)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NewListRow(busy: _creating, onTap: _creating ? null : _create),
              if (!snap.hasData)
                for (var i = 0; i < 3; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
                    child: const Row(
                      children: [
                        VSkeleton(width: 76, height: 56),
                        SizedBox(width: 14),
                        Expanded(child: VSkeleton(height: 30)),
                      ],
                    ),
                  )
              else if (lists.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    tracks ? l10n.pickerEmptyTracks : l10n.pickerEmptyAlbums,
                    style: VText.ui(14, color: c.ink2, height: 1.45),
                  ),
                )
              else
                for (final (i, list) in lists.indexed)
                  _ListRow(
                    key: ValueKey('picker-list-$i'),
                    list: list,
                    onTap: () => Navigator.of(context).pop(list),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// "Nueva lista": un cuadro punteado en énfasis con el +, el texto y "→",
/// entre dos líneas.
class _NewListRow extends StatelessWidget {
  const _NewListRow({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      key: const ValueKey('picker-new-list'),
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border.symmetric(horizontal: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            DashedBox(
              size: 56,
              color: c.accentText,
              child: busy
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 1.6, color: c.accentText),
                    )
                  : VIconView(VIcon.plus, size: 20, color: c.accentText, strokeWidth: 1.4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.l10n.listNew,
                style: VText.ui(17, weight: 600, color: c.accentText),
              ),
            ),
            Text('→', style: VText.ui(16, color: c.accentText)),
          ],
        ),
      ),
    );
  }
}

/// Una de mis listas: sus portadas apiladas, el nombre, "Lista · 12
/// canciones" y un + con borde.
class _ListRow extends StatelessWidget {
  const _ListRow({super.key, required this.list, required this.onTap});

  final MusicList list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(bottom: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: CoverStack(
                urls: list.covers,
                single: list.coverUrl,
                size: 56,
                separator: c.sheet,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.display(19, weight: 700, stretch: 75, height: 1.05, tracking: 0),
                  ),
                  const SizedBox(height: 6),
                  VMono(
                    '${list.kind.label(l10n)} · ${list.itemType.count(list.count, l10n)}',
                    size: 10,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: pressed ? c.ink : c.lineStrong),
              ),
              child: VIconView(VIcon.plus, size: 14, color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
