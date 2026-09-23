import 'package:flutter/material.dart';

import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/auth_page.dart';
import '../widgets/email_password_form.dart';
import 'welcome_screen.dart';

/// Correo y contraseña de una cuenta nueva. Al crearla, la sesión cambia y
/// `main.dart` muestra el onboarding (nombre, color, foto y @usuario).
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final services = ServicesScope.of(context);
    return AuthPage(
      showBack: true,
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Crea tu '),
            TextSpan(
              text: 'cuenta',
              style: VText.display(42, italic: true, color: c.accent),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      subtitle:
          'Con tu correo y una contraseña. Después eliges tu nombre, tu color y tu @usuario.',
      footer: Center(
        child: TextButton(
          key: const ValueKey('signup-to-signin'),
          onPressed: () {
            Navigator.of(context).pop();
            WelcomeScreen.openSignIn(context);
          },
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '¿Ya tienes cuenta? ', style: VText.ui(14, color: c.text2)),
                TextSpan(
                  text: 'Inicia sesión',
                  style: VText.ui(14, weight: 700, color: c.accent),
                ),
              ],
            ),
          ),
        ),
      ),
      child: EmailPasswordForm(
        submitLabel: 'Continuar',
        newPassword: true,
        onSubmit: (email, password) async {
          await services.auth.signUp(email: email, password: password);
          // El inicio ya cambió debajo; se quitan las pantallas de cuenta.
          if (context.mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
      ),
    );
  }
}
