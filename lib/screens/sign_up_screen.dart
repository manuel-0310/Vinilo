import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../util/email.dart';
import '../widgets/auth_page.dart';
import '../widgets/email_password_form.dart';
import '../widgets/line_field.dart';
import '../widgets/username_field.dart';
import '../widgets/v_buttons.dart';
import 'welcome_screen.dart';

/// Largo mínimo de una contraseña nueva. Al entrar se aceptan las de 6 o
/// más (las cuentas de antes), para no dejar fuera a nadie.
const int newPasswordMin = EmailPasswordForm.newPasswordMin;

/// Límite del nombre (el mismo de "Editar perfil").
const int nameMaxLength = 24;

/// Crear la cuenta en una sola pantalla: nombre, @usuario (con "✓
/// Disponible" en vivo), correo y contraseña. Al enviar crea la cuenta de
/// Auth y después el perfil con el color de énfasis por defecto; la foto se
/// pone después. Si el @usuario se lo lleva alguien justo en medio, la
/// cuenta ya existe y `main.dart` muestra "Completa tu perfil".
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  String? _username;
  bool _busy = false;
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = context.l10n;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final username = _username;
    setState(() {
      _error = null;
      _nameError = name.isEmpty ? l.authNameMissing : null;
      _usernameError = username == null ? l.usernameEmpty : null;
      _emailError = email.isEmpty
          ? l.authEmailMissing
          : looksLikeEmail(email)
              ? null
              : l.authInvalidEmail;
      _passwordError =
          password.length < newPasswordMin ? l.authPasswordTooShort(newPasswordMin) : null;
    });
    if (username == null ||
        _nameError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    final services = ServicesScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final User user;
    try {
      user = await services.auth.signUp(email: email, password: password);
    } catch (e) {
      if (!mounted) return;
      final message = friendlyError(e, l);
      final code = e is FirebaseAuthException ? e.code : '';
      setState(() {
        _busy = false;
        switch (code) {
          case 'email-already-in-use' || 'invalid-email' || 'missing-email':
            _emailError = message;
          case 'weak-password':
            _passwordError = message;
          default:
            _error = message;
        }
      });
      return;
    }
    try {
      await services.users.create(
        uid: user.uid,
        name: name,
        username: username,
        colorValue: ViniloPalette.defaultAccent.toARGB32(),
      );
    } catch (e) {
      // La cuenta ya existe: debajo, `main.dart` muestra "Completa tu
      // perfil" para terminarlo.
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l))));
    }
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final termsStyle = VText.ui(12.5, color: c.inactive, height: 1.45);
    final linkStyle = termsStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: c.inactive,
    );
    return AuthScaffold(
      title: l.signUpTitle,
      bodyTop: 32,
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LineField(
              label: l.authNameLabel,
              fieldKey: const ValueKey('name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              inputFormatters: [LengthLimitingTextInputFormatter(nameMaxLength)],
              error: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _usernameFocus.requestFocus(),
            ),
            const SizedBox(height: 20),
            UsernameField(
              label: l.authUsernameLabel,
              focusNode: _usernameFocus,
              textInputAction: TextInputAction.next,
              error: _usernameError,
              onChanged: (v) => setState(() {
                _username = v;
                _usernameError = null;
              }),
              onSubmitted: _emailFocus.requestFocus,
            ),
            const SizedBox(height: 20),
            LineField(
              label: l.authEmailLabel,
              hint: l.authEmailPlaceholder,
              fieldKey: const ValueKey('email-field'),
              controller: _email,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
              error: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 20),
            LineField(
              label: l.authPasswordLabel,
              hint: l.authPasswordNewPlaceholder(newPasswordMin),
              fieldKey: const ValueKey('password-field'),
              controller: _password,
              focusNode: _passwordFocus,
              obscure: true,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              error: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('auth-error'),
              style: VText.ui(13, color: c.danger, height: 1.35),
            ),
            const SizedBox(height: 14),
          ],
          // Términos y Privacidad se ven como en el prototipo; todavía no
          // abren nada.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.signUpTermsStart),
                TextSpan(text: l.signUpTerms, style: linkStyle),
                TextSpan(text: l.signUpTermsMiddle),
                TextSpan(text: l.signUpPrivacy, style: linkStyle),
                TextSpan(text: l.signUpTermsEnd),
              ],
            ),
            style: termsStyle,
          ),
          const SizedBox(height: 14),
          VPrimaryButton(
            key: const ValueKey('auth-submit'),
            label: l.signUpSubmit,
            busy: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 14),
          AuthSwitchLine(
            key: const ValueKey('signup-to-signin'),
            question: l.signUpHaveAccount,
            action: l.signUpSignIn,
            onTap: () {
              Navigator.of(context).pop();
              WelcomeScreen.openSignIn(context);
            },
          ),
        ],
      ),
    );
  }
}
