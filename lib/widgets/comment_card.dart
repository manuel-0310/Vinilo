import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import 'feed_card.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

/// Un comentario sobre un disco, como en "Comentarios destacados": la nota
/// en 52 (en el tono de la portada), el nombre y la hora, la cita en
/// Newsreader entre comillas y "♥ N · Responder". Al tocarlo se abre su
/// hilo; el nombre lleva al perfil. Va sin margen a los lados (lo pone
/// quien la usa) y con una línea suave debajo, salvo la última.
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.entry,
    this.maxLines = 4,
    this.index,
    this.tone,
    this.last = false,
    this.onTap,
    this.onReply,
    this.replyKey,
  });

  final RatingEntry entry;
  final int? maxLines;

  /// Posición en la lista; solo sirve para las llaves de prueba.
  final int? index;

  /// Color de la nota (el tono de la portada; por defecto, el énfasis).
  final Color? tone;

  /// La última no lleva línea debajo.
  final bool last;

  /// Otro toque en lugar de abrir el hilo (null = abrirlo).
  final VoidCallback? onTap;

  /// Dentro del hilo: "Responder" llama a esto en vez de abrirlo.
  final VoidCallback? onReply;
  final Key? replyKey;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => openThread(context, ratingId: entry.id, initial: entry),
      child: Container(
        // Arriba 16; abajo 16 menos los 8 que la fila de acciones reparte
        // para agrandar el toque.
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        decoration: last
            ? null
            : BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '${entry.score}',
                maxLines: 1,
                softWrap: false,
                style: VText.display(52, weight: 700, height: 0.8, tracking: 0, color: tone ?? c.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => openUser(context, entry.user.uid),
                          child: Text(
                            entry.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VText.ui(14, weight: 600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      VMono(timeAgo(entry.updatedAt, context.l10n), size: 10, tracking: 0.06, color: c.ink4),
                    ],
                  ),
                  if (entry.hasNote) ...[
                    const SizedBox(height: 8),
                    Text(
                      '“${entry.note.trim()}”',
                      maxLines: maxLines,
                      overflow: maxLines == null ? null : TextOverflow.ellipsis,
                      style: VText.quote(21, color: c.ink),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      LikeButton(
                        key: index == null ? null : ValueKey('comment-like-$index'),
                        entry: entry,
                      ),
                      const SizedBox(width: 18),
                      if (onReply != null)
                        Pressable(
                          key: replyKey,
                          onTap: onReply,
                          builder: (context, pressed) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: VMono(
                              context.l10n.replyAction,
                              tracking: 0.06,
                              color: pressed ? c.ink : c.ink3,
                            ),
                          ),
                        )
                      else
                        RepliesButton(
                          key: index == null ? null : ValueKey('comment-replies-$index'),
                          entry: entry,
                          label: context.l10n.replyAction,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
