import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
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
            TextSpan(text: context.l10n.signUpTitleStart),
            TextSpan(
              text: context.l10n.signUpTitleAccent,
              style: VText.display(42, italic: true, color: c.accent),
            ),
            TextSpan(text: context.l10n.signUpTitleEnd),
          ],
        ),
      ),
      subtitle: context.l10n.signUpSubtitle,
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
                TextSpan(text: context.l10n.signUpHaveAccount, style: VText.ui(14, color: c.text2)),
                TextSpan(
                  text: context.l10n.signUpSignIn,
                  style: VText.ui(14, weight: 700, color: c.accent),
                ),
              ],
            ),
          ),
        ),
      ),
      child: EmailPasswordForm(
        submitLabel: context.l10n.continueLabel,
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
