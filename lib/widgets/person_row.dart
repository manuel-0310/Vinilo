import 'package:flutter/material.dart';

import '../models/follow.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import 'follow_button.dart';
import 'user_avatar.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

/// Una persona en una lista, con el aspecto de las filas de notificaciones:
/// avatar de 36, nombre y @usuario en mono, línea suave arriba y, a la
/// derecha, el botón de seguir. Al tocar la fila se abre su perfil.
class PersonRow extends StatelessWidget {
  const PersonRow({super.key, required this.person, this.trailing});

  final PersonInfo person;

  /// Reemplaza al botón de seguir (`SizedBox.shrink()` para nada).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: () => openUser(context, person.uid),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(top: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: person.name,
              color: Color(person.colorValue),
              url: person.avatarUrl,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(14.5, weight: 600, height: 1.35),
                  ),
                  if (person.username != null) ...[
                    const SizedBox(height: 3),
                    VMono(
                      person.handle,
                      size: 10,
                      tracking: 0.06,
                      color: c.ink4,
                      uppercase: false,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ?? FollowButton(person: person, compact: true),
          ],
        ),
      ),
    );
  }
}
