import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import 'sheet.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

/// Una opción del menú "···": texto de 16 y, a la derecha, una flecha o una
/// aclaración en mono ("No verás su actividad"). Las que reportan o
/// bloquean van en `danger`.
class MenuSheetItem<T> {
  const MenuSheetItem({
    required this.value,
    required this.label,
    this.hint,
    this.danger = false,
    this.strong = false,
    this.keyName,
  });

  /// Lo que devuelve la hoja al tocarla.
  final T value;
  final String label;

  /// Aclaración a la derecha en lugar de la flecha.
  final String? hint;
  final bool danger;

  /// En 600 (la última, "Bloquear").
  final bool strong;
  final String? keyName;
}

/// El menú "···" de un perfil o de un comentario: hoja con el asa, una
/// etiqueta mono ("@santi", "Calificación de @tomasg"), las opciones entre
/// líneas y "Cancelar". Devuelve el valor de la opción elegida, o null.
Future<T?> showMenuSheet<T>(
  BuildContext context, {
  required String overline,
  required List<MenuSheetItem<T>> items,
}) {
  return showVSheet<T>(context, (_) => _MenuSheet<T>(overline: overline, items: items));
}

class _MenuSheet<T> extends StatelessWidget {
  const _MenuSheet({required this.overline, required this.items});

  final String overline;
  final List<MenuSheetItem<T>> items;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      key: const ValueKey('menu-sheet'),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.buttonLine)),
      ),
      padding: EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, math.max(38.0, bottomInset + 4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VMono(overline, maxLines: 1),
          ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, item) in items.indexed)
                  _MenuRow<T>(item: item, last: i == items.length - 1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VSecondaryButton(
            key: const ValueKey('menu-cancel'),
            label: context.l10n.cancel,
            center: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.item, required this.last});

  final MenuSheetItem<T> item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = item.danger ? c.danger : c.ink;
    return Pressable(
      // Con el tipo exacto: `ValueKey<String?>` no es igual a `ValueKey<String>`.
      key: item.keyName == null ? null : ValueKey<String>(item.keyName!),
      onTap: () => Navigator.of(context).pop(item.value),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: last ? null : Border(bottom: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VText.ui(16, weight: item.strong ? 600 : 500, color: color),
              ),
            ),
            const SizedBox(width: 12),
            if (item.hint != null)
              VMono(item.hint!, size: 10, tracking: 0.06, color: c.ink4, maxLines: 1)
            else
              Text(
                '→',
                style: VText.ui(
                  16,
                  weight: item.strong ? 600 : 500,
                  color: item.danger ? c.danger : c.ink4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
