import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../util/email.dart';
import '../widgets/auth_page.dart';
import '../widgets/line_field.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';
import 'welcome_screen.dart';

/// Entrar con correo y contraseña. El campo dice "Correo o usuario", como el
/// prototipo, pero por ahora solo se entra con el correo: con un @usuario
/// avisa debajo. Apple y Google se ven y todavía no hacen nada.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = context.l10n;
    final identifier = _identifier.text.trim();
    final identifierError = identifier.isEmpty
        ? l.authEmailMissing
        : looksLikeEmail(identifier)
            ? null
            : l.signInEmailOnly;
    final passwordError = _password.text.isEmpty ? l.authMissingPassword : null;
    setState(() {
      _identifierError = identifierError;
      _passwordError = passwordError;
    });
    if (identifierError != null || passwordError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ServicesScope.of(context)
          .auth
          .signIn(email: identifier, password: _password.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      final message = friendlyError(e, context.l10n);
      final aboutEmail = e is FirebaseAuthException &&
          (e.code == 'invalid-email' || e.code == 'missing-email' || e.code == 'user-disabled');
      setState(() {
        if (aboutEmail) {
          _identifierError = message;
        } else {
          _passwordError = message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final services = ServicesScope.of(context);
    final typed = _identifier.text.trim();
    final target = await showVSheet<String>(
      context,
      (_) => _ResetSheet(initialEmail: looksLikeEmail(typed) ? typed : ''),
    );
    if (target == null || target.isEmpty || !mounted) return;
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
    final l = context.l10n;
    return AuthScaffold(
      title: l.signInTitle,
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LineField(
              label: l.signInIdentifierLabel,
              fieldKey: const ValueKey('email-field'),
              controller: _identifier,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              error: _identifierError,
              errorKey: const ValueKey('signin-identifier-error'),
              onChanged: (_) {
                if (_identifierError != null) setState(() => _identifierError = null);
              },
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 22),
            LineField(
              label: l.authPasswordLabel,
              fieldKey: const ValueKey('password-field'),
              controller: _password,
              focusNode: _passwordFocus,
              obscure: _obscure,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              error: _passwordError,
              errorKey: const ValueKey('auth-error'),
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              onSubmitted: (_) => _submit(),
              trailing: Pressable(
                key: const ValueKey('password-toggle'),
                onTap: () => setState(() => _obscure = !_obscure),
                builder: (context, pressed) => Opacity(
                  opacity: pressed ? 0.6 : 1,
                  child: VMono(_obscure ? l.authShow : l.authHide),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: VTextLink(
                l.authForgotPassword,
                key: const ValueKey('forgot-password'),
                style: VText.ui(14, color: c.ink2),
                onTap: _forgot,
              ),
            ),
          ],
        ),
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VPrimaryButton(
            key: const ValueKey('auth-submit'),
            label: l.signInSubmit,
            busy: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          const AuthDivider(),
          const SizedBox(height: 8),
          // Se ven como en el prototipo; entrar con Apple o Google todavía
          // no existe.
          VSecondaryButton(
            key: const ValueKey('signin-apple'),
            label: l.authApple,
            center: true,
            fontSize: 15,
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          VSecondaryButton(
            key: const ValueKey('signin-google'),
            label: l.authGoogle,
            center: true,
            fontSize: 15,
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          AuthSwitchLine(
            key: const ValueKey('signin-to-signup'),
            question: l.signInNoAccount,
            action: l.signInCreateOne,
            onTap: () {
              Navigator.of(context).pop();
              WelcomeScreen.openSignUp(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Pide (o confirma) el correo al que mandar el enlace de recuperación.
class _ResetSheet extends StatefulWidget {
  const _ResetSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends State<_ResetSheet> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid => looksLikeEmail(_email.text);

  void _send() {
    if (_valid) Navigator.of(context).pop(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SheetScaffold(
      title: l.resetTitle,
      subtitle: l.resetBody,
      titleSize: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LineField(
            label: l.authEmailLabel,
            hint: l.authEmailPlaceholder,
            fieldKey: const ValueKey('reset-email-field'),
            controller: _email,
            autofocus: widget.initialEmail.isEmpty,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 28),
          VPrimaryButton(
            key: const ValueKey('reset-send'),
            label: l.send,
            onPressed: _valid ? _send : null,
          ),
        ],
      ),
    );
  }
}
