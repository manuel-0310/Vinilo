import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/v_sections.dart';
import 'card_parts.dart';
import 'share_card_data.dart';

/// "Historia · artista": su foto en un círculo que se sale por arriba a la
/// derecha, el nombre, mi promedio en sus discos y mis 3 mejores.
class ArtistShareCard extends StatelessWidget {
  const ArtistShareCard({super.key, required this.data, required this.accent});

  final ArtistCardData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ShareCardFrame(
      format: ShareCardFormat.story,
      accent: accent,
      padding: EdgeInsets.zero,
      child: Builder(builder: (context) {
        final c = VColors.of(context);
        final l = context.l10n;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -70,
              top: -40,
              width: 300,
              height: 300,
              child: ClipOval(child: AlbumCover(url: data.artist.image ?? data.artist.imageSmall)),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VMono(l.shareCardArtist, size: 10, tracking: 0.1, color: c.inkA(0.7)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        data.artist.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VText.display(84, weight: 900, height: 0.8),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: VMono(
                                '${l.shareCardMyAverage}\n${l.shareCardRatedOf(data.rated, data.total)}',
                                size: 10,
                                tracking: 0.1,
                                color: c.ink3,
                              ),
                            ),
                            Text(
                              Score.formatAverage(data.average, l.localeName),
                              style: VText.display(88, weight: 700, height: 0.78, tracking: 0, color: c.accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final (i, r) in data.top.indexed)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineSoft))),
                          child: Row(
                            children: [
                              SizedBox(width: 24, child: VMono('${i + 1}', size: 10, tracking: 0, color: c.ink4)),
                              const SizedBox(width: 12),
                              CardCover(url: r.album.smallCover, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r.album.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: VText.display(18, weight: 700, stretch: 75, height: 1, tracking: 0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${r.score}', style: cardNumber(30)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  CardFooter(lineColor: c.line, leading: CardHandle(person: data.person)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
