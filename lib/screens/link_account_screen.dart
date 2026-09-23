import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/auth_page.dart';
import '../widgets/email_password_form.dart';
import '../widgets/user_avatar.dart';
import 'welcome_screen.dart';

/// Quien venía usando Vinilo con la sesión anónima de antes guarda aquí su
/// cuenta: se vincula un correo y una contraseña a la misma sesión
/// (`linkWithCredential`), así el uid, las notas, los favoritos y el perfil
/// siguen siendo los suyos. Después elige su @usuario.
class LinkAccountScreen extends StatelessWidget {
  const LinkAccountScreen({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _signInInstead(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = VColors.of(ctx);
        return AlertDialog(
          title: Text('¿Entrar con otra cuenta?', style: VText.display(28)),
          content: Text(
            'Esta sesión tiene ${_count(profile.ratingsCount)} y tu perfil. Si entras con otra cuenta, todo eso queda fuera de tu alcance. Para conservarlo, guarda esta sesión con un correo y una contraseña.',
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Volver'),
            ),
            TextButton(
              key: const ValueKey('link-signin-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Entrar de todos modos',
                style: VText.ui(14, weight: 700, color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok == true && context.mounted) WelcomeScreen.openSignIn(context);
  }

  static String _count(int n) => n == 1 ? '1 nota' : '$n notas';

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final services = ServicesScope.of(context);
    return AuthPage(
      leading: UserAvatar(
        name: profile.name,
        color: profile.color,
        url: profile.avatarUrl,
        size: 56,
        ring: true,
      ),
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Guarda tu '),
            TextSpan(
              text: 'cuenta',
              style: VText.display(42, italic: true, color: c.accent),
            ),
            TextSpan(text: ', ${profile.name}.'),
          ],
        ),
      ),
      subtitle:
          'Vinilo ahora entra con correo y contraseña. Vincúlalos a esta sesión y conservas ${_count(profile.ratingsCount)}, tus favoritos y tu perfil en cualquier dispositivo.',
      footer: Center(
        child: TextButton(
          key: const ValueKey('link-signin'),
          onPressed: () => _signInInstead(context),
          child: Text(
            'Ya tengo una cuenta',
            style: VText.ui(14, weight: 700, color: c.text2),
          ),
        ),
      ),
      child: EmailPasswordForm(
        submitLabel: 'Guardar mi cuenta',
        newPassword: true,
        autofocus: false,
        onSubmit: (email, password) async {
          // El uid se conserva; `userChanges` avisa y main pasa a elegir el
          // @usuario.
          await services.auth.linkEmail(email: email, password: password);
        },
      ),
    );
  }
}
