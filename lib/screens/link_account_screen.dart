import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
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
          title: Text(ctx.l10n.linkOtherTitle, style: VText.display(28)),
          content: Text(
            ctx.l10n.linkOtherBody(profile.ratingsCount),
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.back),
            ),
            TextButton(
              key: const ValueKey('link-signin-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.l10n.linkOtherConfirm,
                style: VText.ui(14, weight: 700, color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok == true && context.mounted) WelcomeScreen.openSignIn(context);
  }

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
            TextSpan(text: context.l10n.linkTitleStart),
            TextSpan(
              text: context.l10n.linkTitleAccent,
              style: VText.display(42, italic: true, color: c.accent),
            ),
            TextSpan(text: context.l10n.linkTitleEnd(profile.name)),
          ],
        ),
      ),
      subtitle: context.l10n.linkSubtitle(profile.ratingsCount),
      footer: Center(
        child: TextButton(
          key: const ValueKey('link-signin'),
          onPressed: () => _signInInstead(context),
          child: Text(
            context.l10n.linkHaveAccount,
            style: VText.ui(14, weight: 700, color: c.text2),
          ),
        ),
      ),
      child: EmailPasswordForm(
        submitLabel: context.l10n.linkSubmit,
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
