import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_sections.dart';
import 'card_parts.dart';
import 'share_card_data.dart';

/// "Historia · amigo": la afinidad en grande, una frase según el
/// porcentaje y la comparación de 3 discos (2 en los que coincidimos y 1 en
/// el que no).
class FriendShareCard extends StatelessWidget {
  const FriendShareCard({super.key, required this.data, required this.accent});

  final FriendCardData data;
  final Color accent;

  static String phrase(FriendCardData data, AppLocalizations l) {
    final name = data.friend.firstName;
    return switch (friendVerdict(data.percent)) {
      FriendVerdict.almostAll => l.shareCardFriendAlmostAll(name),
      FriendVerdict.quiteALot => l.shareCardFriendQuiteALot(name),
      FriendVerdict.opposites => l.shareCardFriendOpposites(name),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ShareCardFrame(
      format: ShareCardFormat.story,
      accent: accent,
      child: Builder(builder: (context) {
        final c = VColors.of(context);
        final l = context.l10n;
        Widget avatar(CardPerson p) => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
              child: UserAvatar(name: p.name, color: p.color, url: p.avatarUrl, size: 44),
            );
        Widget scoreCell(Widget child) => SizedBox(width: 36, child: Align(alignment: Alignment.centerRight, child: child));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(child: VMono(l.shareCardCompatibility, size: 10, tracking: 0.1, color: c.inkA(0.7))),
                // 44 + 3 de contorno a cada lado; el segundo se monta 12.
                SizedBox(
                  width: 50 * 2 - 12,
                  height: 50,
                  child: Stack(
                    children: [
                      Positioned(left: 0, child: avatar(data.me)),
                      Positioned(left: 50 - 12, child: avatar(data.friend)),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${data.percent}%',
                    style: VText.display(176, weight: 900, height: 0.78, tracking: -0.02, color: c.accent),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  phrase(data, l),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: VText.display(24, weight: 700, stretch: 75, height: 1.05, tracking: 0),
                ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      scoreCell(VMono(l.shareCardMe, size: 9.5, tracking: 0.08, color: c.ink4, maxLines: 1)),
                      const SizedBox(width: 8),
                      scoreCell(VMono(data.friend.firstName, size: 9.5, tracking: 0.08, color: c.ink4, maxLines: 1)),
                    ],
                  ),
                ),
                for (final row in data.rows)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineSoft))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VMono(row.agree ? l.shareCardAgree : l.shareCardDisagree, size: 9, tracking: 0.08, color: c.ink4),
                              const SizedBox(height: 3),
                              Text(
                                row.album.album.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VText.display(17, weight: 700, stretch: 75, height: 1, tracking: 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        scoreCell(Text('${row.album.mine}', style: cardNumber(28))),
                        const SizedBox(width: 8),
                        scoreCell(Text('${row.album.theirs}', style: cardNumber(28))),
                      ],
                    ),
                  ),
              ],
            ),
            CardFooter(
              lineColor: c.line,
              leading: VMono('${data.me.label} × ${data.friend.label}', size: 10, tracking: 0.08, color: c.ink, maxLines: 1),
            ),
          ],
        );
      }),
    );
  }
}
