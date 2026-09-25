import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../screens/routes.dart';
import '../services/services.dart';
import '../theme/oklch.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'album_cover.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

/// El diario como sliver. Agrupado, cada mes lleva su encabezado ("SEPTIEMBRE
/// 2026 · 4", con línea arriba); sin agrupar (ordenado por nota), solo las
/// filas. `monthCounts` da la cifra de cada mes cuando se muestra solo una
/// parte (el perfil enseña las 5 últimas).
class DiaryList extends StatelessWidget {
  const DiaryList({
    super.key,
    required this.entries,
    this.grouped = true,
    this.monthCounts,
  });

  final List<RatingEntry> entries;
  final bool grouped;

  /// Notas por mes (clave `año*12 + mes`); si falta, se cuentan las que hay.
  final Map<int, int>? monthCounts;

  static int monthKey(DateTime d) => d.year * 12 + d.month;

  /// Cuántas notas hay en cada mes.
  static Map<int, int> countByMonth(Iterable<RatingEntry> entries) {
    final out = <int, int>{};
    for (final e in entries) {
      out.update(monthKey(e.createdAt), (n) => n + 1, ifAbsent: () => 1);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final counts = monthCounts ?? countByMonth(entries);
    final items = <Object>[];
    int? currentMonth;
    for (final e in entries) {
      if (grouped) {
        final key = monthKey(e.createdAt);
        if (key != currentMonth) {
          currentMonth = key;
          items.add(e.createdAt);
        }
      }
      items.add(e);
    }
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is DateTime) {
          return VSectionHeader(
            monthYear(item, context.l10n),
            action: '${counts[monthKey(item)] ?? 0}',
            accentAction: false,
          );
        }
        // La última de cada mes no lleva línea: debajo va el encabezado
        // siguiente, que trae la suya.
        final last = i == items.length - 1 || items[i + 1] is DateTime;
        return DiaryRow(entry: item as RatingEntry, last: last);
      },
    );
  }
}

/// Una fila del diario: el día (24) y el mes en mono, la portada de 48, el
/// disco y el artista, y la nota en 36 en el tono de su portada.
class DiaryRow extends StatefulWidget {
  const DiaryRow({super.key, required this.entry, this.last = false});

  final RatingEntry entry;
  final bool last;

  @override
  State<DiaryRow> createState() => _DiaryRowState();
}

class _DiaryRowState extends State<DiaryRow> {
  Color? _coverColor;
  String? _askedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _askPalette();
  }

  @override
  void didUpdateWidget(DiaryRow old) {
    super.didUpdateWidget(old);
    if (old.entry.albumId != widget.entry.albumId) _coverColor = null;
    _askPalette();
  }

  void _askPalette() {
    final url = widget.entry.album.smallCover;
    if (url == null || _askedFor == url) return;
    _askedFor = url;
    final palette = ServicesScope.of(context).palette;
    final known = palette.cached(url);
    if (known != null) {
      _coverColor = known;
      return;
    }
    palette.dominant(url).then((color) {
      if (color != null && mounted && _askedFor == url) setState(() => _coverColor = color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final entry = widget.entry;
    final heroTag = 'diary-${entry.id}';
    final cover = _coverColor;
    final month = monthShort(entry.createdAt, context.l10n);
    return Pressable(
      key: ValueKey('diary-${entry.albumId}'),
      onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: widget.last ? null : Border(bottom: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.createdAt.day}',
                    style: VText.display(24, weight: 700, stretch: 65, height: 1, tracking: 0),
                  ),
                  // "SEP": las tres primeras letras, como el prototipo.
                  VMono(
                    month.characters.take(3).toString(),
                    size: 9,
                    color: c.ink4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AlbumCover(url: entry.album.smallCover, size: 48, heroTag: heroTag),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(15, weight: 600),
                  ),
                  Text(
                    entry.album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12.5, color: c.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.score}',
              style: VText.display(
                36,
                weight: 700,
                height: 1,
                tracking: 0,
                color: cover == null ? c.accent : coverTone(cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
