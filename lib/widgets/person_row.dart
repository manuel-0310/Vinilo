import 'package:flutter/material.dart';

import '../models/follow.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import 'follow_button.dart';
import 'user_avatar.dart';

/// Una persona en una lista: avatar, nombre, @usuario y el botón de seguir.
/// Al tocar el cuerpo se abre su perfil.
class PersonRow extends StatelessWidget {
  const PersonRow({super.key, required this.person, this.trailing});

  final PersonInfo person;

  /// Reemplaza al botón de seguir (por ejemplo, nada).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openUser(context, person.uid),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 9),
          child: Row(
            children: [
              UserAvatar(
                name: person.name,
                color: Color(person.colorValue),
                url: person.avatarUrl,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(15, weight: 700),
                    ),
                    if (person.username != null)
                      Text(
                        person.handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(12, color: c.text2),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ?? FollowButton(person: person, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
