import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../theme/vinilo_theme.dart';
import 'cover_stack.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

/// Una lista en una fila (la pestaña Listas del perfil): sus portadas
/// apiladas de 64 (o la portada que eligió su autora), el nombre en 21
/// condensado, "Lista · 12 canciones" en mono y "→". Línea suave debajo.
class ListRowTile extends StatelessWidget {
  const ListRowTile({
    super.key,
    required this.list,
    required this.onTap,
    this.trailing,
  });

  final MusicList list;
  final VoidCallback onTap;

  /// Reemplaza a la flecha.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(bottom: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            CoverStack(urls: list.covers, single: list.coverUrl, size: 64, offset: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VText.display(21, weight: 700, stretch: 75, height: 1.05, tracking: 0),
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
            trailing ?? Text('→', style: VText.ui(16, color: c.ink4)),
          ],
        ),
      ),
    );
  }
}
