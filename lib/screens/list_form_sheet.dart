import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/music_list.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/sheet.dart';

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

/// Crear o editar una lista: nombre, descripción opcional, tipo (Lista o
/// Ranking) y de qué es (canciones o discos). Con `fixedItemType` no se
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
    final c = VColors.of(context);
    return SheetScaffold(
      title: widget.title ?? (_editing ? 'Editar lista' : 'Nueva lista'),
      subtitle: _editing
          ? widget.initial!.typeLabel
          : 'Un ranking va numerado y se ordena arrastrando.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('list-name'),
            controller: _name,
            autofocus: widget.initialName == null,
            maxLength: MusicList.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            style: VText.ui(17, weight: 600),
            decoration: InputDecoration(
              hintText: 'Nombre de la lista',
              counterStyle: VText.label(10, color: c.text3),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('list-description'),
            controller: _description,
            maxLength: MusicList.maxDescriptionLength,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            style: VText.ui(15),
            decoration: InputDecoration(
              hintText: 'Descripción (opcional)',
              counterStyle: VText.label(10, color: c.text3),
            ),
          ),
          if (!_editing) ...[
            const SizedBox(height: 14),
            Text('TIPO', style: VText.label(11, color: c.text3)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Choice(
                    key: const ValueKey('kind-list'),
                    label: 'Lista',
                    hint: 'Sin orden fijo',
                    icon: Icons.format_list_bulleted_rounded,
                    selected: _kind == ListKind.list,
                    onTap: () => setState(() => _kind = ListKind.list),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Choice(
                    key: const ValueKey('kind-ranking'),
                    label: 'Ranking',
                    hint: 'Numerado, del 1 en adelante',
                    icon: Icons.format_list_numbered_rounded,
                    selected: _kind == ListKind.ranking,
                    onTap: () => setState(() => _kind = ListKind.ranking),
                  ),
                ),
              ],
            ),
            if (widget.fixedItemType == null) ...[
              const SizedBox(height: 16),
              Text('¿DE QUÉ?', style: VText.label(11, color: c.text3)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Choice(
                      key: const ValueKey('type-tracks'),
                      label: 'Canciones',
                      hint: 'De cualquier disco',
                      icon: Icons.music_note_rounded,
                      selected: _itemType == ListItemType.tracks,
                      onTap: () => setState(() => _itemType = ListItemType.tracks),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      key: const ValueKey('type-albums'),
                      label: 'Discos',
                      hint: 'Álbumes completos',
                      icon: Icons.album_rounded,
                      selected: _itemType == ListItemType.albums,
                      onTap: () => setState(() => _itemType = ListItemType.albums),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 26),
          FilledButton(
            key: const ValueKey('list-submit'),
            onPressed: _canSubmit ? _submit : null,
            child: Text(widget.submitLabel ?? (_editing ? 'Guardar' : 'Crear lista')),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = selected ? c.accent : c.text2;
    return Material(
      color: selected ? c.accent.withValues(alpha: 0.14) : c.surface2,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? c.accent.withValues(alpha: 0.6) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(label, style: VText.ui(14, weight: 700, color: color)),
              Text(hint, style: VText.ui(11, color: c.text3, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
