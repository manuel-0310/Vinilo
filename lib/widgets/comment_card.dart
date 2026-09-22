import 'package:flutter/material.dart';

import '../models/rating.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'feed_card.dart';
import 'score_widgets.dart';
import 'user_avatar.dart';

/// Un comentario sobre un disco: quién, cuándo, qué dijo, su nota y el botón
/// de "me gusta". Al tocar el cuerpo se abre el perfil de la persona.
class CommentCard extends StatelessWidget {
  const CommentCard({super.key, required this.entry, this.maxLines = 4});

  final RatingEntry entry;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      child: Material(
        color: c.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openUser(context, entry.user.uid),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      name: entry.user.name,
                      color: entry.user.color,
                      url: entry.user.avatarUrl,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VText.ui(14, weight: 700),
                          ),
                          Text(
                            timeAgo(entry.updatedAt),
                            style: VText.ui(11, color: c.text3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScoreNumeral(score: entry.score, size: 34),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  entry.note,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: VText.display(18, italic: true, height: 1.2),
                ),
                const SizedBox(height: 10),
                LikeButton(entry: entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
