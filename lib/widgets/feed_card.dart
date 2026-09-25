import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../screens/routes.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'album_cover.dart';
import 'user_avatar.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// Una fila de "Actividad de tus amigos": quién calificó (avatar de 22,
/// "Nombre calificó" y la hora), el disco (portada de 76, título y "Artista
/// · año") con la nota en 64 y su veredicto, el comentario en Newsreader si
/// lo hay, y "♥ Te gusta · Comentar". Las filas se separan con una línea.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.entry,
    required this.heroTag,
    this.index = 0,
    this.first = false,
    this.last = false,
  });

  final RatingEntry entry;
  final String heroTag;

  /// Posición en la lista; solo sirve para las llaves de prueba.
  final int index;

  /// La primera va pegada al encabezado (6 arriba en vez de 16).
  final bool first;

  /// La última no lleva línea debajo.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    void openProfile() => openUser(context, entry.user.uid);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
      child: Container(
        // Abajo 16 menos los 8 que la fila de acciones reparte arriba y
        // abajo para agrandar el toque.
        padding: EdgeInsets.fromLTRB(VSpace.page, first ? 6 : 16, VSpace.page, 8),
        decoration: last
            ? null
            : BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  key: ValueKey('feed-user-$index'),
                  onTap: openProfile,
                  child: UserAvatar(
                    name: entry.user.name,
                    color: entry.user.color,
                    url: entry.user.avatarUrl,
                    size: 22,
                    initialSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: openProfile,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: entry.user.name,
                            style: VText.ui(13, weight: 600, color: c.ink),
                          ),
                          TextSpan(text: l.feedRatedSuffix),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(13, color: c.ink2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                VMono(timeAgo(entry.updatedAt, l), tracking: 0.06, color: c.ink2),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AlbumCover(url: entry.album.smallCover, size: 76, heroTag: heroTag),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.album.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VText.display(24, weight: 700, stretch: 75, height: 1, tracking: 0),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.album.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(13, color: c.ink3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.score}',
                      style: VText.display(64, weight: 700, height: 0.8, tracking: 0, color: c.accent),
                    ),
                    const SizedBox(height: 6),
                    VMono(
                      Score.label(entry.score, l),
                      size: 9.5,
                      tracking: 0.1,
                      color: c.accent,
                    ),
                  ],
                ),
              ],
            ),
            if (entry.hasNote) ...[
              const SizedBox(height: 12),
              Text('“${entry.note}”', style: VText.quote(21, color: c.ink)),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                LikeButton(key: ValueKey('feed-like-$index'), entry: entry, showLabel: true),
                const SizedBox(width: 18),
                RepliesButton(key: ValueKey('feed-replies-$index'), entry: entry),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Acción de texto mono de las filas ("♥ Te gusta", "Comentar"): 8 de
/// relleno arriba y abajo para que el toque no sea de 14 px, que quien la
/// usa descuenta de su espacio.
class _MonoAction extends StatelessWidget {
  const _MonoAction({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: child,
      ),
    );
  }
}

/// "Comentar" o "N respuestas": abre el hilo de la nota. Si todavía no
/// tiene respuestas, entra directo a escribir.
class RepliesButton extends StatelessWidget {
  const RepliesButton({super.key, required this.entry, this.label});

  final RatingEntry entry;

  /// Otro texto para cuando no hay respuestas ("Responder" en los
  /// comentarios del disco); con respuestas siempre dice cuántas.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final count = entry.repliesCount;
    final text = count == 0
        ? (label ?? context.l10n.feedComment)
        : context.l10n.feedReplies(count);
    return _MonoAction(
      onTap: () => openThread(
        context,
        ratingId: entry.id,
        initial: entry,
        compose: count == 0,
      ),
      child: VMono(text, tracking: 0.06, color: c.ink3),
    );
  }
}

/// El corazón de una nota: lleno y en énfasis si me gusta, vacío si no. Con
/// `showLabel` dice "Te gusta" o "Me gusta" (la actividad); si no, cuántos
/// "me gusta" tiene (los comentarios).
class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.entry, this.showLabel = false});

  final RatingEntry entry;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final me = CurrentUser.maybeOf(context);
    final liked = me != null && entry.likedByMe(me.uid);
    final color = liked ? c.accent : c.ink3;
    final text = showLabel
        ? (liked ? l.feedLiked : l.feedLike)
        : (entry.likes > 0 ? '${entry.likes}' : null);
    return _MonoAction(
      onTap: me == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              ServicesScope.of(context).ratings.toggleLike(entry, me);
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIconView(liked ? VIcon.heartFilled : VIcon.heart, size: 10, color: color),
          if (text != null) ...[
            const SizedBox(width: 6),
            VMono(text, tracking: 0.06, color: color),
          ],
        ],
      ),
    );
  }
}
