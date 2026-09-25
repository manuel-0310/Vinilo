import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../widgets/line_field.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';

/// Lo que devuelve el formulario de una lista.
class ListDraft {
  const ListDraft({
    required this.name,
    required this.description,
    required this.kind,
    required this.itemType,
  });

  final String name;
  final String description;
  final ListKind kind;
  final ListItemType itemType;
}

/// Crear o editar una lista: nombre (con "13/60"), descripción opcional,
/// tipo (Lista o Ranking) y de qué es (canciones o discos), con "Crear
/// lista →" fijo abajo. Con `fixedItemType` no se
/// pregunta de qué es; con `initial` se edita (nombre y descripción; el
/// tipo no cambia). Devuelve null si se cierra sin guardar.
Future<ListDraft?> showListForm(
  BuildContext context, {
  MusicList? initial,
  String? initialName,
  ListItemType? fixedItemType,
  ListKind? initialKind,
  String? title,
  String? submitLabel,
}) {
  return showVSheet<ListDraft>(
    context,
    (_) => _ListForm(
      initial: initial,
      initialName: initialName,
      fixedItemType: fixedItemType,
      initialKind: initialKind,
      title: title,
      submitLabel: submitLabel,
    ),
  );
}

class _ListForm extends StatefulWidget {
  const _ListForm({
    required this.initial,
    required this.initialName,
    required this.fixedItemType,
    required this.initialKind,
    required this.title,
    required this.submitLabel,
  });

  final MusicList? initial;
  final String? initialName;
  final ListItemType? fixedItemType;
  final ListKind? initialKind;
  final String? title;
  final String? submitLabel;

  @override
  State<_ListForm> createState() => _ListFormState();
}

class _ListFormState extends State<_ListForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? widget.initialName ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late ListKind _kind = widget.initial?.kind ?? widget.initialKind ?? ListKind.list;
  late ListItemType _itemType =
      widget.initial?.itemType ?? widget.fixedItemType ?? ListItemType.tracks;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(
      ListDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        kind: _kind,
        itemType: _itemType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetScaffold(
      title: widget.title ?? (_editing ? l10n.listEdit : l10n.listNew),
      subtitle: _editing
          ? widget.initial!.typeLabel(l10n)
          : l10n.listFormSubtitle,
      footer: VPrimaryButton.accent(
        key: const ValueKey('list-submit'),
        label: widget.submitLabel ?? (_editing ? l10n.save : l10n.listCreate),
        onPressed: _canSubmit ? _submit : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          LineField(
            label: l10n.listFormName,
            hint: l10n.listNameHint,
            fieldKey: const ValueKey('list-name'),
            controller: _name,
            autofocus: widget.initial == null && widget.initialName == null,
            maxLength: MusicList.maxNameLength,
            fontSize: 22,
            fontWeight: 600,
            padding: const EdgeInsets.symmetric(vertical: 10),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          LineField(
            label: l10n.listFormDescription,
            hint: l10n.listFormOptional,
            fieldKey: const ValueKey('list-description'),
            controller: _description,
            maxLength: MusicList.maxDescriptionLength,
            minLines: 1,
            maxLines: 3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textCapitalization: TextCapitalization.sentences,
          ),
          if (!_editing) ...[
            const SizedBox(height: 18),
            VMono(l10n.listFormKind),
            const SizedBox(height: 10),
            _Pair(
              first: ChoiceBox(
                key: const ValueKey('kind-list'),
                icon: VIcon.list,
                title: l10n.listKindList,
                subtitle: l10n.listKindListHint,
                selected: _kind == ListKind.list,
                onTap: () => _pickKind(ListKind.list),
              ),
              second: ChoiceBox(
                key: const ValueKey('kind-ranking'),
                icon: VIcon.ranking,
                title: l10n.listKindRanking,
                subtitle: l10n.listKindRankingHint,
                selected: _kind == ListKind.ranking,
                onTap: () => _pickKind(ListKind.ranking),
              ),
            ),
            if (widget.fixedItemType == null) ...[
              const SizedBox(height: 18),
              VMono(l10n.listFormContent),
              const SizedBox(height: 10),
              _Pair(
                first: ChoiceBox(
                  key: const ValueKey('type-tracks'),
                  icon: VIcon.track,
                  title: l10n.listTypeTracks,
                  subtitle: l10n.listTypeTracksHint,
                  selected: _itemType == ListItemType.tracks,
                  onTap: () => _pickType(ListItemType.tracks),
                ),
                second: ChoiceBox(
                  key: const ValueKey('type-albums'),
                  icon: VIcon.disc,
                  title: l10n.listTypeAlbums,
                  subtitle: l10n.listTypeAlbumsHint,
                  selected: _itemType == ListItemType.albums,
                  onTap: () => _pickType(ListItemType.albums),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _pickKind(ListKind kind) {
    HapticFeedback.selectionClick();
    setState(() => _kind = kind);
  }

  void _pickType(ListItemType type) {
    HapticFeedback.selectionClick();
    setState(() => _itemType = type);
  }
}

/// Dos cajas lado a lado, separadas 8 y del mismo alto.
class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: first),
          const SizedBox(width: 8),
          Expanded(child: second),
        ],
      ),
    );
  }
}
