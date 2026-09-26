import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/v_sections.dart';
import 'card_parts.dart';
import 'share_card_data.dart';

/// "Historia · disco" y "Cuadrado · disco": la portada, la nota en el tono
/// claro de la portada sobre su tono oscuro, la regla y quién calificó.
class AlbumShareCard extends StatelessWidget {
  const AlbumShareCard({
    super.key,
    required this.data,
    required this.accent,
    this.coverColor,
    this.format = ShareCardFormat.story,
  });

  final AlbumCardData data;
  final Color accent;

  /// Color dominante de la portada (sin él, el énfasis).
  final Color? coverColor;
  final ShareCardFormat format;

  @override
  Widget build(BuildContext context) {
    final tones = CardTones.from(coverColor ?? accent);
    return ShareCardFrame(
      format: format,
      accent: accent,
      background: tones.background,
      padding: EdgeInsets.all(format == ShareCardFormat.story ? 28 : 22),
      child: format == ShareCardFormat.story ? _Story(data: data, tones: tones) : _Square(data: data, tones: tones),
    );
  }
}

String _artistLine(AlbumCardData d) => d.album.subtitle;

class _Story extends StatelessWidget {
  const _Story({required this.data, required this.tones});

  final AlbumCardData data;
  final CardTones tones;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VMono(l.shareCardRated, size: 10, tracking: 0.1, color: c.inkA(0.7)),
                VMono(cardDate(data.ratedAt, l.localeName), size: 10, tracking: 0.1, color: c.inkA(0.7)),
              ],
            ),
            const SizedBox(height: 20),
            CardCover(url: data.album.bestCover, size: 304),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.album.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VText.display(28, weight: 700, stretch: 75, height: 0.95, tracking: 0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _artistLine(data),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(15, weight: 600, color: tones.artist),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('${data.score}', style: VText.display(110, weight: 700, height: 0.78, tracking: 0, color: tones.score)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var k = 1; k <= 10; k++) ...[
                    if (k > 1) const SizedBox(width: 3),
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: cardRulerCell(k, data.score).height,
                        alignment: Alignment.bottomCenter,
                        child: ColoredBox(
                          color: tones.score.withValues(alpha: cardRulerCell(k, data.score).opacity),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        CardFooter(leading: CardHandle(person: data.person)),
      ],
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.data, required this.tones});

  final AlbumCardData data;
  final CardTones tones;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardCover(url: data.album.bestCover, size: 170),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VMono(l.shareCardRated, size: 9.5, tracking: 0.1, color: c.inkA(0.7)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text('${data.score}', style: VText.display(120, weight: 700, height: 0.78, tracking: 0, color: tones.score)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VText.display(28, weight: 700, stretch: 75, height: 0.95, tracking: 0),
            ),
            const SizedBox(height: 5),
            Text(
              _artistLine(data),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VText.ui(14, weight: 600, color: tones.artist),
            ),
          ],
        ),
        CardFooter(
          top: 12,
          logoSize: 20,
          leading: CardHandle(person: data.person, avatar: false, size: 9.5),
        ),
      ],
    );
  }
}

/// "Historia · reseña": la portada chica, la nota y el comentario en
/// Newsreader itálica, que se achica si es largo (hasta 180 letras).
class ReviewShareCard extends StatelessWidget {
  const ReviewShareCard({super.key, required this.data, required this.accent, this.coverColor});

  final AlbumCardData data;
  final Color accent;
  final Color? coverColor;

  /// Tamaño de la cita según el largo: 32 como el prototipo y menos para
  /// que un comentario largo quepa entero.
  static double quoteSize(String note) => note.length > 130
      ? 22
      : note.length > 90
          ? 26
          : note.length > 60
              ? 29
              : 32;

  @override
  Widget build(BuildContext context) {
    final tones = CardTones.from(coverColor ?? accent);
    return ShareCardFrame(
      format: ShareCardFormat.story,
      accent: accent,
      child: Builder(builder: (context) {
        final c = VColors.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: Row(
                children: [
                  CardCover(url: data.album.smallCover, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.album.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: VText.display(22, weight: 700, stretch: 75, height: 0.95, tracking: 0),
                        ),
                        const SizedBox(height: 5),
                        VMono(_artistLine(data), size: 10, tracking: 0.08, color: c.ink3, maxLines: 1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('${data.score}', style: VText.display(64, weight: 700, height: 0.8, tracking: 0, color: tones.score)),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  '“${data.note}”',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 14,
                  style: VText.quote(quoteSize(data.note), height: 1.12, color: c.ink),
                ),
              ),
            ),
            CardFooter(lineColor: c.line, leading: CardHandle(person: data.person)),
          ],
        );
      }),
    );
  }
}
