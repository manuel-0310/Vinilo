import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'album_cover.dart';
import 'score_widgets.dart';

/// Lista de notas del diario como sliver, con separadores por mes opcionales.
class DiaryList extends StatelessWidget {
  const DiaryList({super.key, required this.entries, this.grouped = true});

  final List<RatingEntry> entries;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final items = <Object>[];
    String? currentMonth;
    for (final e in entries) {
      if (grouped) {
        final key = monthYear(e.createdAt, context.l10n);
        if (key != currentMonth) {
          currentMonth = key;
          items.add(key);
        }
      }
      items.add(e);
    }
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is String) {
          return Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, i == 0 ? 4 : 22, VSpace.page, 8),
            child: Text(item.toUpperCase(), style: VText.label(11, color: c.text3)),
          );
        }
        return DiaryRow(entry: item as RatingEntry)
            .animate()
            .fadeIn(delay: (30 * (i % 10)).ms, duration: 350.ms);
      },
    );
  }
}

/// Una fila del diario: día, portada, disco, artista, línea y nota.
class DiaryRow extends StatelessWidget {
  const DiaryRow({super.key, required this.entry});

  final RatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final heroTag = 'diary-${entry.id}';
    return InkWell(
      key: ValueKey('diary-${entry.albumId}'),
      onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Text(
                    '${entry.createdAt.day}',
                    style: VText.display(24, height: 1),
                  ),
                  Text(
                    monthShort(entry.createdAt, context.l10n).toUpperCase(),
                    style: VText.label(9, color: c.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AlbumCover(
              url: entry.album.smallCover,
              size: 56,
              radius: 10,
              heroTag: heroTag,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(15, weight: 700),
                  ),
                  Text(
                    entry.album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12, color: c.text2),
                  ),
                  if (entry.hasNote)
                    Text(
                      entry.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.display(14, italic: true, color: c.text3, height: 1.3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ScoreNumeral(score: entry.score, size: 32),
          ],
        ),
      ),
    );
  }
}
