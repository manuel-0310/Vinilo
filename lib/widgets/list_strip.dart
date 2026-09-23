import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/music_list.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import 'list_mosaic.dart';

/// Fila horizontal de listas: mosaico, nombre y "Ranking · 12 canciones".
class ListStrip extends StatelessWidget {
  const ListStrip({
    super.key,
    required this.lists,
    required this.keyPrefix,
    this.size = 132,
  });

  final List<MusicList> lists;
  final String keyPrefix;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return SizedBox(
      height: size + 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: lists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final list = lists[i];
          return GestureDetector(
            key: ValueKey('$keyPrefix-$i'),
            onTap: () => openList(context, listId: list.id, initial: list),
            child: SizedBox(
              width: size,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListMosaic(covers: list.covers, size: size, radius: 16),
                  const SizedBox(height: 8),
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(13, weight: 700, height: 1.25),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${list.kind.label} · ${list.itemType.count(list.count)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12, color: c.text2, height: 1.3),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (50 * i).ms, duration: 400.ms)
              .slideX(begin: 0.08, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

/// Una lista como fila (para elegir a cuál agregar).
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
              ListMosaic(covers: list.covers, size: 50, radius: 10),
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
                      '${list.kind.label} · ${list.itemType.count(list.count)}',
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
