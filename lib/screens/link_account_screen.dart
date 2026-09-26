import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../widgets/auth_page.dart';
import '../widgets/email_password_form.dart';
import '../widgets/sheet.dart';
import 'welcome_screen.dart';

/// Quien venía usando Vinilo con la sesión anónima de antes guarda aquí su
/// cuenta: se vincula un correo y una contraseña a la misma sesión
/// (`linkWithCredential`), así el uid, las notas, los favoritos y el perfil
/// siguen siendo los suyos. Después elige su @usuario. Sin diseño propio: el
/// mismo andamio que Crear cuenta.
class LinkAccountScreen extends StatelessWidget {
  const LinkAccountScreen({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _signInInstead(BuildContext context) async {
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.linkOtherTitle,
      message: l.linkOtherBody(profile.ratingsCount),
      confirmLabel: l.linkOtherConfirm,
      danger: true,
      confirmKey: const ValueKey('link-signin-confirm'),
    );
    if (ok && context.mounted) WelcomeScreen.openSignIn(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = ServicesScope.of(context);
    return AuthScaffold(
      showBack: false,
      title: l.linkTitle,
      bodyTop: 16,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthParagraph(l.linkSubtitle(profile.ratingsCount)),
          const SizedBox(height: 28),
          EmailPasswordForm(
            submitLabel: l.linkSubmit,
            newPassword: true,
            onSubmit: (email, password) async {
              // El uid se conserva; `userChanges` avisa y main pasa a elegir
              // el @usuario.
              await services.auth.linkEmail(email: email, password: password);
            },
          ),
        ],
      ),
      bottom: Center(
        child: AuthSwitchLine(
          key: const ValueKey('link-signin'),
          question: '',
          action: l.linkHaveAccount,
          onTap: () => _signInInstead(context),
        ),
      ),
    );
  }
}
