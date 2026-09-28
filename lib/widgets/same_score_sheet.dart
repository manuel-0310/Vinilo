import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../models/same_score.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'album_cover.dart';
import 'sheet.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// "Otros discos calificados con N → 4" debajo de "Guardar mi nota": botón
/// de 48 con borde; a la derecha cuántos hay ("Ninguno" y más apagado si no
/// hay). Abre la hoja con esos discos.
class SameScoreButton extends StatelessWidget {
  const SameScoreButton({
    super.key,
    required this.score,
    required this.mine,
    required this.except,
    this.tone,
  });

  final int score;

  /// Mis notas (null mientras cargan).
  final List<RatingEntry>? mine;

  /// El disco que se está calificando (no cuenta).
  final String except;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final list = mine;
    final count = list == null ? null : ratedWith(list, score, except: except).length;
    return Opacity(
      opacity: count == 0 ? 0.5 : 1,
      child: Pressable(
        key: const ValueKey('rating-compare'),
        onTap: list == null
            ? null
            : () => showSameScoreSheet(context, mine: list, score: score, except: except, tone: tone),
        builder: (context, pressed) => Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: pressed ? c.inkA(0.04) : null,
            border: Border.all(color: pressed ? c.ink : c.lineStrong),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.rateCompare(score),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.ui(15, weight: 500),
                ),
              ),
              const SizedBox(width: 12),
              VMono(
                count == null ? '' : (count == 0 ? l.rateCompareNone : '$count'),
                key: const ValueKey('rating-compare-count'),
                size: 11,
                tracking: 0.06,
                color: c.inkA(0.6),
              ),
              const SizedBox(width: 10),
              Text('→', style: VText.ui(15, weight: 500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// La hoja "Tus discos con N": el número en 84 con el veredicto y cuántos
/// discos, cerrar, y la lista (portada de 52, título, "Artista · año" y el
/// mes en que lo califiqué). Sin discos: "Aún no has calificado…".
Future<void> showSameScoreSheet(
  BuildContext context, {
  required List<RatingEntry> mine,
  required int score,
  required String except,
  Color? tone,
}) {
  return showVSheet<void>(
    context,
    (_) => _SameScoreSheet(
      albums: ratedWith(mine, score, except: except),
      score: score,
      tone: tone,
    ),
  );
}

class _SameScoreSheet extends StatelessWidget {
  const _SameScoreSheet({required this.albums, required this.score, this.tone});

  final List<RatingEntry> albums;
  final int score;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final color = tone ?? c.accentText;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      key: const ValueKey('compare-sheet'),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VMono(l.rateCompareTitle),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score',
                          style: VText.display(84, weight: 800, height: 0.78, tracking: 0, color: color),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Score.label(score, l),
                                  style: VText.display(24, weight: 700, stretch: 70, height: 1, tracking: 0, color: color),
                                ),
                                const SizedBox(height: 4),
                                VMono(l.countAlbums(albums.length), key: const ValueKey('compare-count')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              VIconButton(
                key: const ValueKey('compare-close'),
                icon: VIcon.close,
                iconSize: 16,
                tooltip: l.cancel,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: c.line),
          Flexible(
            child: albums.isEmpty
                ? Padding(
                    padding: EdgeInsets.fromLTRB(0, 36, 0, 36 + bottomInset),
                    child: Text(
                      l.rateCompareEmpty(score),
                      key: const ValueKey('compare-empty'),
                      textAlign: TextAlign.center,
                      style: VText.ui(15, height: 1.45, color: c.inkA(0.55)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: 24 + bottomInset),
                    itemCount: albums.length,
                    itemBuilder: (context, i) {
                      final entry = albums[i];
                      final album = entry.album;
                      return Container(
                        key: ValueKey('compare-$i'),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
                        child: Row(
                          children: [
                            AlbumCover(url: album.smallCover, size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    album.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: VText.ui(16, weight: 600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    album.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: VText.ui(13, color: c.ink3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            VMono(
                              '${monthShort(entry.updatedAt, l)} ${entry.updatedAt.year}',
                              size: 10,
                              tracking: 0.06,
                              color: c.ink4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
