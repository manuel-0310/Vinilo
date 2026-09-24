import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../theme/vinilo_theme.dart';
import 'list_mosaic.dart';

/// Una lista como fila compacta: mosaico (o portada) pequeño a la izquierda
/// y, a la derecha, el nombre, el tipo y el número de elementos. Se usa en
/// el perfil y al elegir a qué lista agregar algo.
class ListRowTile extends StatelessWidget {
  const ListRowTile({
    super.key,
    required this.list,
    required this.onTap,
    this.trailing,
  });

  final MusicList list;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ListMosaic(
                covers: list.covers,
                coverUrl: list.coverUrl,
                size: 52,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(15, weight: 700),
                    ),
                    Text(
                      '${list.kind.label(context.l10n)} · ${list.itemType.count(list.count, context.l10n)}',
                      style: VText.ui(12, color: c.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ?? Icon(Icons.add_circle_outline_rounded, color: c.text3),
            ],
          ),
        ),
      ),
    );
  }
}
