import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/rating.dart';
import '../screens/routes.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'album_cover.dart';
import 'score_widgets.dart';
import 'user_avatar.dart';

/// Una entrada del feed: quién calificó qué, con qué nota y qué dijo.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.entry,
    required this.heroTag,
    this.index = 0,
  });

  final RatingEntry entry;
  final String heroTag;

  /// Posición en la lista; solo sirve para las llaves de prueba.
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Score.color(entry.score);
    return Material(
      color: VColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    key: ValueKey('feed-user-$index'),
                    onTap: () => openUser(context, entry.user.uid),
                    child: UserAvatar(
                      name: entry.user.name,
                      color: entry.user.color,
                      url: entry.user.avatarUrl,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openUser(context, entry.user.uid),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: entry.user.name,
                              style: VText.ui(14, weight: 700),
                            ),
                            TextSpan(
                              text: ' calificó',
                              style: VText.ui(14, color: VColors.text2),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    timeAgo(entry.updatedAt),
                    style: VText.ui(12, color: VColors.text3),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AlbumCover(
                    url: entry.album.smallCover,
                    size: 78,
                    radius: 12,
                    heroTag: heroTag,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.album.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: VText.display(23, height: 1.05),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.album.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(13, color: VColors.text2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ScoreNumeral(score: entry.score, size: 46),
                ],
              ),
              if (entry.hasNote) ...[
                const SizedBox(height: 12),
                Text(
                  '“${entry.note}”',
                  style: VText.display(19, italic: true, height: 1.2),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  LikeButton(key: ValueKey('feed-like-$index'), entry: entry),
                  const Spacer(),
                  Text(
                    Score.label(entry.score).toUpperCase(),
                    style: VText.label(10, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.entry});

  final RatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final me = CurrentUser.maybeOf(context);
    final liked = me != null && entry.likedByMe(me.uid);
    final color = liked ? VColors.danger : VColors.text3;
    return Material(
      color: liked ? VColors.danger.withValues(alpha: 0.12) : VColors.surface2,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: me == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                ServicesScope.of(context).ratings.toggleLike(entry, me.uid);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: color,
              )
                  .animate(key: ValueKey(liked))
                  .scale(
                    begin: const Offset(1.35, 1.35),
                    end: const Offset(1, 1),
                    duration: 320.ms,
                    curve: Curves.elasticOut,
                  ),
              if (entry.likes > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '${entry.likes}',
                  style: VText.ui(12, weight: 700, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
