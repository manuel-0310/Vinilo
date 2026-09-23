import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';

typedef EmailPasswordSubmit = Future<void> Function(String email, String password);

/// Correo y contraseña con el mismo carácter de la app. Lo comparten crear
/// cuenta, iniciar sesión y guardar una sesión anónima; los errores de
/// Firebase se muestran debajo, en español.
class EmailPasswordForm extends StatefulWidget {
  const EmailPasswordForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initialEmail = '',
    this.newPassword = false,
    this.onForgotPassword,
    this.autofocus = true,
  });

  final String submitLabel;
  final EmailPasswordSubmit onSubmit;
  final String initialEmail;

  /// True cuando la contraseña se está creando (autocompletado y pista de
  /// longitud mínima); false al iniciar sesión.
  final bool newPassword;

  /// Muestra "¿Olvidaste tu contraseña?" y lo llama con el correo escrito.
  final ValueChanged<String>? onForgotPassword;
  final bool autofocus;

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  static const int minPassword = 6;

  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String get _emailText => _email.text.trim();

  bool get _emailLooksValid {
    final at = _emailText.indexOf('@');
    return at > 0 &&
        _emailText.indexOf('.', at) > at + 1 &&
        !_emailText.endsWith('.') &&
        !_emailText.contains(' ');
  }

  bool get _canSubmit =>
      !_busy && _emailLooksValid && _password.text.length >= minPassword;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_emailText, _password.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final passwordHint = widget.newPassword
        ? 'Contraseña (mínimo $minPassword caracteres)'
        : 'Contraseña';
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('email-field'),
            controller: _email,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            style: VText.ui(17, weight: 600),
            decoration: const InputDecoration(hintText: 'Correo'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('password-field'),
            controller: _password,
            focusNode: _passwordFocus,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: [
              widget.newPassword
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ],
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
            style: VText.ui(17, weight: 600),
            decoration: InputDecoration(
              hintText: passwordHint,
              suffixIcon: IconButton(
                key: const ValueKey('password-toggle'),
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 21,
                  color: c.text3,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (widget.onForgotPassword != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('forgot-password'),
                onPressed: () => widget.onForgotPassword!(_emailText),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: VText.ui(13, weight: 700, color: c.accent),
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_rounded, size: 16, color: c.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            key: const ValueKey('auth-error'),
                            style: VText.ui(13, weight: 600, color: c.danger, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            key: const ValueKey('auth-submit'),
            onPressed: _canSubmit ? _submit : null,
            child: _busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.onAccent,
                    ),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
