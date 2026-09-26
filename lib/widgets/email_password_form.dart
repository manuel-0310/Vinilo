import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../util/auth_errors.dart';
import '../util/email.dart';
import 'line_field.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

typedef EmailPasswordSubmit = Future<void> Function(String email, String password);

/// Correo y contraseña con los campos de línea del rediseño y el botón
/// debajo. Lo usa guardar una sesión anónima (Iniciar sesión y Crear cuenta
/// tienen su propio orden). Los errores salen debajo de cada campo.
class EmailPasswordForm extends StatefulWidget {
  const EmailPasswordForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initialEmail = '',
    this.newPassword = false,
    this.autofocus = false,
  });

  final String submitLabel;
  final EmailPasswordSubmit onSubmit;
  final String initialEmail;

  /// True cuando la contraseña se está creando: pide [newPasswordMin]
  /// caracteres y ofrece la del llavero; false al iniciar sesión.
  final bool newPassword;
  final bool autofocus;

  /// Largo mínimo de una contraseña nueva.
  static const int newPasswordMin = 8;

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  int get _minPassword => widget.newPassword ? EmailPasswordForm.newPasswordMin : 6;

  Future<void> _submit() async {
    if (_busy) return;
    final l = context.l10n;
    final email = _email.text.trim();
    setState(() {
      _emailError = email.isEmpty
          ? l.authEmailMissing
          : looksLikeEmail(email)
              ? null
              : l.authInvalidEmail;
      _passwordError = _password.text.isEmpty
          ? l.authMissingPassword
          : _password.text.length < _minPassword
              ? l.authPasswordTooShort(_minPassword)
              : null;
    });
    if (_emailError != null || _passwordError != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await widget.onSubmit(email, _password.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = friendlyError(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LineField(
            label: l.authEmailLabel,
            hint: l.authEmailPlaceholder,
            fieldKey: const ValueKey('email-field'),
            controller: _email,
            autofocus: widget.autofocus,
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
            hint: widget.newPassword ? l.authPasswordNewPlaceholder(_minPassword) : null,
            fieldKey: const ValueKey('password-field'),
            controller: _password,
            focusNode: _passwordFocus,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: [
              widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
            ],
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
          const SizedBox(height: 28),
          VPrimaryButton(
            key: const ValueKey('auth-submit'),
            label: widget.submitLabel,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
