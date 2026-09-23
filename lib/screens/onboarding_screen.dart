import 'package:flutter/material.dart';

import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/auth_page.dart';
import 'profile_form.dart';

/// Perfil de una cuenta recién creada: nombre, color, foto y @usuario.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final services = ServicesScope.of(context);
    final email = services.auth.email;
    return AuthPage(
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Así te '),
            TextSpan(
              text: 'verán',
              style: VText.display(42, italic: true, color: c.accent),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      subtitle:
          'Tu nombre, tu color y un @usuario único para que te encuentren. Todo se puede cambiar después.',
      footer: email == null
          ? null
          : Center(
              child: TextButton(
                key: const ValueKey('onboarding-signout'),
                onPressed: services.auth.signOut,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Entraste como $email · ',
                        style: VText.ui(13, color: c.text3),
                      ),
                      TextSpan(
                        text: 'Salir',
                        style: VText.ui(13, weight: 700, color: c.text2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      child: ProfileForm(
        submitLabel: 'Empezar',
        showColor: true,
        showUsername: true,
        forUid: uid,
        onSubmit: (edit) async {
          String? url;
          if (edit.avatar != null) {
            url = await services.users.uploadAvatar(uid, edit.avatar!);
          }
          await services.users.create(
            uid: uid,
            name: edit.name,
            colorValue: edit.colorValue,
            username: edit.username!,
            avatarUrl: url,
          );
        },
      ),
    );
  }
}
