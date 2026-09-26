import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/v_sections.dart';
import 'card_parts.dart';
import 'share_card_data.dart';

/// "Historia · lista" (rejilla de 9) y "Cuadrado · lista" (rejilla de 4),
/// sobre el tono oscuro de la primera portada.
class ListShareCard extends StatelessWidget {
  const ListShareCard({
    super.key,
    required this.list,
    required this.accent,
    this.coverColor,
    this.format = ShareCardFormat.story,
  });

  final MusicList list;
  final Color accent;
  final Color? coverColor;
  final ShareCardFormat format;

  /// Las portadas que dibuja (para precargarlas).
  static List<String?> coversFor(MusicList list, ShareCardFormat format) =>
      listGridCovers(list, format == ShareCardFormat.story ? 9 : 4);

  @override
  Widget build(BuildContext context) {
    final tones = CardTones.from(coverColor ?? accent);
    final story = format == ShareCardFormat.story;
    return ShareCardFrame(
      format: format,
      accent: accent,
      background: tones.background,
      padding: EdgeInsets.all(story ? 28 : 22),
      child: story ? _Story(list: list) : _Square(list: list),
    );
  }
}

String _count(MusicList list, AppLocalizations l) => list.itemType == ListItemType.tracks
    ? l.shareCardTracks(list.count)
    : l.shareCardAlbums(list.count);

class _Story extends StatelessWidget {
  const _Story({required this.list});

  final MusicList list;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final handle = list.owner.username == null ? list.owner.name : '@${list.owner.username}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VMono(
              list.isRanking ? l.shareCardRankingBy(handle) : l.shareCardListBy(handle),
              size: 10,
              tracking: 0.1,
              color: c.inkA(0.7),
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            Text(
              list.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: VText.display(64, weight: 800, height: 0.85),
            ),
          ],
        ),
        CardCoverGrid(covers: ListShareCard.coversFor(list, ShareCardFormat.story), columns: 3),
        CardFooter(
          leading: VMono(
            '${_count(list, l)} · ${l.shareCardSaves(list.savedBy.length)}',
            size: 10,
            tracking: 0.08,
            color: c.ink,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.list});

  final MusicList list;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final handle = list.owner.username == null ? list.owner.name : '@${list.owner.username}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VMono(list.isRanking ? l.shareCardRanking : l.shareCardList, size: 9.5, tracking: 0.1, color: c.inkA(0.7)),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    list.name,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: VText.display(44, weight: 800, height: 0.85, tracking: 0),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.inkA(0.2)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VMono('${_count(list, l)} · $handle', size: 9.5, tracking: 0.08, color: c.ink, maxLines: 2),
                    const SizedBox(height: 8),
                    const CardLogo(size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: CardCoverGrid(covers: ListShareCard.coversFor(list, ShareCardFormat.square), columns: 2),
          ),
        ),
      ],
    );
  }
}
