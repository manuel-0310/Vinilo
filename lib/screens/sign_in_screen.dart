import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../widgets/auth_page.dart';
import '../widgets/email_password_form.dart';
import 'welcome_screen.dart';

/// Entrar con correo y contraseña, con recuperación de contraseña.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _forgot(BuildContext context, String email) async {
    final services = ServicesScope.of(context);
    final target = await showDialog<String>(
      context: context,
      builder: (_) => _ResetDialog(initialEmail: email),
    );
    if (target == null || target.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await services.auth.sendPasswordReset(target);
      messenger.showSnackBar(SnackBar(content: Text(l10n.resetSent(target))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final services = ServicesScope.of(context);
    return AuthPage(
      showBack: true,
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: context.l10n.signInTitleStart),
            TextSpan(
              text: context.l10n.signInTitleAccent,
              style: VText.display(42, italic: true, color: c.accent),
            ),
            TextSpan(text: context.l10n.signInTitleEnd),
          ],
        ),
      ),
      subtitle: context.l10n.signInSubtitle,
      footer: Center(
        child: TextButton(
          key: const ValueKey('signin-to-signup'),
          onPressed: () {
            Navigator.of(context).pop();
            WelcomeScreen.openSignUp(context);
          },
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: context.l10n.signInNoAccount, style: VText.ui(14, color: c.text2)),
                TextSpan(
                  text: context.l10n.signInCreateOne,
                  style: VText.ui(14, weight: 700, color: c.accent),
                ),
              ],
            ),
          ),
        ),
      ),
      child: EmailPasswordForm(
        submitLabel: context.l10n.signIn,
        onForgotPassword: (email) => _forgot(context, email),
        onSubmit: (email, password) async {
          await services.auth.signIn(email: email, password: password);
          if (context.mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
      ),
    );
  }
}

/// Pide (o confirma) el correo al que mandar el enlace de recuperación.
class _ResetDialog extends StatefulWidget {
  const _ResetDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid {
    final s = _email.text.trim();
    final at = s.indexOf('@');
    return at > 0 && s.indexOf('.', at) > at + 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return AlertDialog(
      title: Text(context.l10n.resetTitle, style: VText.display(28)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.resetBody,
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('reset-email-field'),
            controller: _email,
            autofocus: widget.initialEmail.isEmpty,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_valid) Navigator.of(context).pop(_email.text.trim());
            },
            style: VText.ui(16, weight: 600),
            decoration: InputDecoration(hintText: context.l10n.authEmailHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('reset-send'),
          onPressed: _valid ? () => Navigator.of(context).pop(_email.text.trim()) : null,
          child: Text(
            context.l10n.send,
            style: VText.ui(14, weight: 700, color: _valid ? c.accent : c.text3),
          ),
        ),
      ],
    );
  }
}
