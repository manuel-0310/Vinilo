import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_sections.dart';
import 'card_parts.dart';
import 'share_card_data.dart';

/// "Historia · mi perfil": banner (foto o el tono oscuro de mi color), foto,
/// nombre, cifras, favoritos (la app guarda 3, el prototipo muestra 4) y
/// "Sígueme en Vinilo".
class ProfileShareCard extends StatelessWidget {
  const ProfileShareCard({super.key, required this.data, required this.accent});

  final ProfileCardData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = data.profile;
    return ShareCardFrame(
      format: ShareCardFormat.story,
      accent: accent,
      padding: EdgeInsets.zero,
      child: Builder(builder: (context) {
        final c = VColors.of(context);
        final l = context.l10n;
        final average = p.average;
        final favorites = p.favorites.take(3).toList();
        Widget stat(String value, String label, {Color? color, bool first = false}) => Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(first ? 0 : 12, 12, 0, 12),
                decoration: first ? null : BoxDecoration(border: Border(left: BorderSide(color: c.line))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, maxLines: 1, style: VText.display(34, weight: 700, height: 0.85, tracking: 0, color: color)),
                    const SizedBox(height: 4),
                    VMono(label, size: 9.5, tracking: 0.08, color: c.ink3, maxLines: 1),
                  ],
                ),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: p.bannerUrl == null
                        ? ColoredBox(color: c.coverShade(p.color, lightness: 0.35))
                        : AlbumCover(url: p.bannerUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 24,
                    bottom: -48,
                    child: UserAvatar(name: p.name, color: p.color, url: p.avatarUrl, size: 88, ring: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: VText.display(52, weight: 800, height: 0.85, tracking: 0)),
                        const SizedBox(height: 6),
                        VMono(
                          l.shareCardSince(p.handle.isEmpty ? p.name : p.handle, '${p.createdAt.year}'),
                          size: 10,
                          tracking: 0.08,
                          color: c.ink3,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(horizontal: BorderSide(color: c.line)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            stat('${p.ratingsCount}', l.shareCardStatAlbums, first: true),
                            stat('${data.reviews}', l.shareCardStatReviews),
                            stat(
                              average == null ? '–' : Score.formatAverage(average, l.localeName),
                              l.shareCardStatAverage,
                              color: c.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (favorites.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VMono(l.shareCardFavorites(favorites.length), size: 10, tracking: 0.1, color: c.ink3),
                          const SizedBox(height: 10),
                          CardCoverGrid(covers: [for (final a in favorites) a.smallCover], columns: 3),
                        ],
                      ),
                    Container(
                      height: 48,
                      color: c.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              l.shareCardFollowMe,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(14, weight: 600, color: c.onAccent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('VINILO', style: VText.display(20, weight: 900, height: 0.8, tracking: 0, color: c.onAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// "Historia · mi semana": fondo de énfasis con el texto en `onAccent`.
class WeekShareCard extends StatelessWidget {
  const WeekShareCard({super.key, required this.data, required this.accent});

  final WeekCardData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = ShareCardFrame.themeFor(accent).extension<ViniloPalette>()!;
    return ShareCardFrame(
      format: ShareCardFormat.story,
      accent: accent,
      background: theme.accent,
      child: Builder(builder: (context) {
        final c = VColors.of(context);
        final l = context.l10n;
        final on = c.onAccent;
        return DefaultTextStyle.merge(
          style: TextStyle(color: on),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VMono(l.shareCardMyWeek(weekRange(data.from, data.to, l.localeName)), size: 10, tracking: 0.1, color: on),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(l.shareCardWeekCount(data.count), style: VText.display(96, weight: 900, height: 0.8, color: on)),
                  ),
                ],
              ),
              Column(
                children: [
                  for (final r in data.rows)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: on.withValues(alpha: 0.2)))),
                      child: Row(
                        children: [
                          CardCover(url: r.album.smallCover, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.album.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: VText.display(18, weight: 700, stretch: 75, height: 1, tracking: 0, color: on),
                                ),
                                const SizedBox(height: 3),
                                VMono(r.album.artist, size: 9, tracking: 0.08, color: on, maxLines: 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${r.score}', style: cardNumber(34, color: on)),
                        ],
                      ),
                    ),
                ],
              ),
              CardFooter(
                lineColor: on.withValues(alpha: 0.3),
                logoColor: on,
                barColor: on,
                leading: VMono(data.person.label, size: 10, tracking: 0.08, color: on, maxLines: 1),
              ),
            ],
          ),
        );
      }),
    );
  }
}
