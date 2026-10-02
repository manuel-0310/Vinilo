import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/stats.dart' show accentParts;
import '../services/recovery_service.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../util/email.dart';
import '../widgets/auth_page.dart';
import '../widgets/line_field.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';

/// Abre "Recuperar contraseña" (desde "¿Olvidaste tu contraseña?").
Future<void> openRecoverPassword(BuildContext context, {String initialEmail = ''}) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => RecoverEmailScreen(initialEmail: initialEmail)),
  );
}

/// Paso 1 de 3: el correo de la cuenta y "Enviar código". Si la función de
/// los códigos no está disponible, manda el enlace de Firebase de siempre y
/// vuelve a Iniciar sesión.
class RecoverEmailScreen extends StatefulWidget {
  const RecoverEmailScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<RecoverEmailScreen> createState() => _RecoverEmailScreenState();
}

class _RecoverEmailScreenState extends State<RecoverEmailScreen> {
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final l = context.l10n;
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _error = email.isEmpty ? l.authEmailMissing : l.authInvalidEmail);
      return;
    }
    final services = ServicesScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resendIn = await services.recovery.start(email, lang: l.localeName.startsWith('en') ? 'en' : 'es');
      if (!mounted) return;
      navigator.push(
        CupertinoPageRoute(
          builder: (_) => RecoverCodeScreen(email: email, resendIn: resendIn),
        ),
      );
    } on RecoveryException catch (e) {
      if (e.error == RecoveryError.notAvailable) {
        // Sin la función de códigos: el enlace de Firebase.
        try {
          await services.auth.sendPasswordReset(email);
          messenger.showSnackBar(SnackBar(content: Text(l.resetSent(email))));
          navigator.pop();
        } catch (linkError) {
          if (mounted) setState(() => _error = friendlyError(linkError, l));
        }
      } else if (mounted) {
        setState(() => _error = e.message(l));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      overline: l.recoverStep(1),
      title: l.recoverTitle,
      bodyTop: 14,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthParagraph(l.recoverEmailBody),
          const SizedBox(height: 32),
          LineField(
            label: l.authEmailLabel,
            hint: l.authEmailPlaceholder,
            fieldKey: const ValueKey('recover-email-field'),
            controller: _email,
            autofocus: widget.initialEmail.isEmpty,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            error: _error,
            errorKey: const ValueKey('recover-email-error'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _send(),
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VPrimaryButton(
            key: const ValueKey('recover-send'),
            label: l.recoverSendCode,
            busy: _busy,
            onPressed: _send,
          ),
          const SizedBox(height: 18),
          AuthSwitchLine(
            key: const ValueKey('recover-to-signin'),
            question: l.recoverRemembered,
            action: l.signUpSignIn,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// Paso 2 de 3: las seis casillas del código y un teclado numérico propio.
/// Al llegar al sexto dígito se comprueba solo. Con un código incorrecto las
/// casillas y el aviso van en rojo, con los intentos que quedan; "Reenviar"
/// se enciende cuando termina la cuenta atrás.
class RecoverCodeScreen extends StatefulWidget {
  const RecoverCodeScreen({super.key, required this.email, this.resendIn = 45});

  final String email;

  /// En cuántos segundos se puede pedir otro código.
  final int resendIn;

  static const int length = 6;

  @override
  State<RecoverCodeScreen> createState() => _RecoverCodeScreenState();
}

class _RecoverCodeScreenState extends State<RecoverCodeScreen> {
  String _code = '';
  bool _busy = false;

  /// El aviso en rojo (código incorrecto, vencido…); con él las casillas
  /// también van en rojo.
  String? _error;

  /// Un aviso que no es error ("Te mandamos un código nuevo").
  String? _notice;

  late DateTime _resendAt = DateTime.now().add(Duration(seconds: widget.resendIn));
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _secondsLeft >= 0) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int get _secondsLeft {
    final ms = _resendAt.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _press(String key) {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      // Después de un error, lo primero que se toca empieza un código nuevo.
      if (_error != null) {
        _error = null;
        _code = '';
      }
      _notice = null;
      if (key == NumberPad.delete) {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
      } else if (_code.length < RecoverCodeScreen.length) {
        _code += key;
      }
    });
    if (_code.length == RecoverCodeScreen.length) _verify();
  }

  Future<void> _verify() async {
    final recovery = ServicesScope.of(context).recovery;
    final navigator = Navigator.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final ticket = await recovery.verify(widget.email, _code);
      HapticFeedback.mediumImpact();
      navigator.pushReplacement(
        CupertinoPageRoute(
          builder: (_) => RecoverNewPasswordScreen(email: widget.email, ticket: ticket),
        ),
      );
    } on RecoveryException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = e.message(l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _secondsLeft > 0) return;
    final recovery = ServicesScope.of(context).recovery;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final resendIn = await recovery.start(widget.email, lang: l.localeName.startsWith('en') ? 'en' : 'es');
      if (!mounted) return;
      setState(() {
        _code = '';
        _error = null;
        _notice = l.recoverCodeSent;
        _resendAt = DateTime.now().add(Duration(seconds: resendIn));
      });
    } on RecoveryException catch (e) {
      if (!mounted) return;
      setState(() {
        final wait = e.retryAfter;
        if (e.error == RecoveryError.throttled && wait != null) {
          _resendAt = DateTime.now().add(Duration(seconds: wait));
        }
        _error = e.message(l);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final body = accentParts(l.recoverCodeBody(widget.email));
    final left = _secondsLeft;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: VIconButton(
                  key: const ValueKey('back'),
                  icon: VIcon.back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VMono(l.recoverStep(2)),
                    const SizedBox(height: 8),
                    Text(
                      l.recoverCodeTitle,
                      key: const ValueKey('auth-title'),
                      style: VText.display(64, weight: 800, height: 0.86, tracking: 0),
                    ),
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: body.before),
                          TextSpan(text: body.accent, style: TextStyle(color: c.ink)),
                          TextSpan(text: body.after),
                        ],
                      ),
                      style: VText.ui(15, height: 1.45, color: c.ink2),
                    ),
                    const SizedBox(height: 32),
                    CodeCells(code: _code, error: _error != null),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      VMono(
                        _error!,
                        key: const ValueKey('recover-code-error'),
                        tracking: 0.06,
                        color: c.danger,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: left > 0
                              ? VMono(
                                  l.recoverResendIn(countdownLabel(left)),
                                  key: const ValueKey('recover-resend-in'),
                                  tracking: 0.06,
                                  color: c.ink4,
                                  maxLines: 1,
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Pressable(
                                    key: const ValueKey('recover-resend'),
                                    onTap: _resend,
                                    builder: (context, pressed) => VMono(
                                      l.recoverResend,
                                      tracking: 0.06,
                                      color: pressed ? c.ink2 : c.ink,
                                    ),
                                  ),
                                ),
                        ),
                        if (_busy)
                          VSpinner(color: c.ink3)
                        else if (_notice != null)
                          VMono(_notice!, tracking: 0.06, color: c.accentText, maxLines: 1),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            NumberPad(onKey: _press),
          ],
        ),
      ),
    );
  }
}

/// Las seis casillas del código: cada una de 64 con el dígito en 44 y una
/// línea debajo (de énfasis en la que toca escribir, de tinta en las
/// llenas, fina en las vacías; todas rojas si el código fue incorrecto).
class CodeCells extends StatelessWidget {
  const CodeCells({super.key, required this.code, this.error = false});

  final String code;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < RecoverCodeScreen.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              key: ValueKey('code-cell-$i'),
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: error
                      ? BorderSide(color: c.danger, width: 2)
                      : i == code.length
                          ? BorderSide(color: c.accentText, width: 2)
                          : i < code.length
                              ? BorderSide(color: c.ink, width: 2)
                              : BorderSide(color: c.lineStrong),
                ),
              ),
              child: Text(
                i < code.length ? code[i] : '',
                style: VText.display(
                  44,
                  weight: 800,
                  height: 1,
                  tracking: 0,
                  color: error ? c.danger : c.ink,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Teclado numérico de la app: tres columnas de teclas planas de 48 sobre el
/// color de las hojas, con el 0 abajo en medio y borrar a su derecha.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.onKey});

  /// Recibe el dígito tocado o [delete].
  final ValueChanged<String> onKey;

  /// Lo que manda la tecla de borrar.
  static const String delete = 'delete';

  static const List<String> _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', delete];

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final bottom = math.max(34.0, MediaQuery.paddingOf(context).bottom + 4);
    return Container(
      key: const ValueKey('number-pad'),
      padding: EdgeInsets.fromLTRB(12, 10, 12, bottom),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < 4; r++)
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : 6),
              child: Row(
                children: [
                  for (var k = 0; k < 3; k++) ...[
                    if (k > 0) const SizedBox(width: 6),
                    Expanded(child: _key(context, c, _keys[r * 3 + k])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, ViniloPalette c, String key) {
    if (key.isEmpty) return const SizedBox(height: 48);
    return Pressable(
      key: ValueKey('pad-$key'),
      onTap: () => onKey(key),
      builder: (context, pressed) => Container(
        height: 48,
        alignment: Alignment.center,
        color: c.inkA(pressed ? 0.16 : 0.06),
        child: key == delete
            ? Semantics(
                label: context.l10n.keypadDelete,
                button: true,
                child: VIconView(VIcon.backspace, size: 22, color: c.ink),
              )
            : Text(key, style: VText.ui(22, weight: 500, height: 1)),
      ),
    );
  }
}

/// Paso 3 de 3: la contraseña nueva con su barra de fuerza de 4 segmentos y
/// los requisitos (8 o más caracteres, un número, distinta a la anterior),
/// repetirla y "Guardar y entrar".
class RecoverNewPasswordScreen extends StatefulWidget {
  const RecoverNewPasswordScreen({super.key, required this.email, required this.ticket});

  final String email;
  final String ticket;

  @override
  State<RecoverNewPasswordScreen> createState() => _RecoverNewPasswordScreenState();
}

class _RecoverNewPasswordScreenState extends State<RecoverNewPasswordScreen> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _repeatFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _passwordError;
  String? _repeatError;

  /// Qué se sabe de "Distinta a la anterior": null hasta comprobarlo al
  /// guardar; false si resultó ser la misma.
  bool? _different;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final l = context.l10n;
    final password = _password.text;
    final passwordError = passwordAcceptable(password) ? null : l.recoverWeak;
    final repeatError = password == _repeat.text ? null : l.recoverMismatch;
    setState(() {
      _passwordError = passwordError;
      _repeatError = repeatError;
    });
    if (passwordError != null || repeatError != null) return;

    final services = ServicesScope.of(context);
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final same = await services.recovery.isCurrentPassword(
        email: widget.email,
        password: password,
        apiKey: services.auth.apiKey,
      );
      if (same) {
        if (mounted) {
          setState(() {
            _different = false;
            _passwordError = l.recoverSamePassword;
          });
        }
        return;
      }
      if (mounted) setState(() => _different = true);
      final name = await services.recovery.finish(
        widget.email,
        ticket: widget.ticket,
        password: password,
      );
      // "Guardar y entrar": con la contraseña nueva, la sesión.
      await services.auth.signIn(email: widget.email, password: password);
      HapticFeedback.mediumImpact();
      navigator.pushAndRemoveUntil(
        CupertinoPageRoute(builder: (_) => RecoverDoneScreen(name: name)),
        (route) => route.isFirst,
      );
    } on RecoveryException catch (e) {
      if (mounted) setState(() => _passwordError = e.message(l));
    } catch (e) {
      if (mounted) setState(() => _passwordError = friendlyError(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final password = _password.text;
    final strength = passwordStrength(password);
    return AuthScaffold(
      overline: l.recoverStep(3),
      title: l.recoverNewTitle,
      bodyTop: 32,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LineField(
            label: l.recoverNewLabel,
            fieldKey: const ValueKey('recover-password-field'),
            controller: _password,
            autofocus: true,
            obscure: _obscure,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword],
            error: _passwordError,
            errorKey: const ValueKey('recover-password-error'),
            onChanged: (_) => setState(() {
              _passwordError = null;
              _different = null;
            }),
            onSubmitted: (_) => _repeatFocus.requestFocus(),
            trailing: Pressable(
              key: const ValueKey('recover-password-toggle'),
              onTap: () => setState(() => _obscure = !_obscure),
              builder: (context, pressed) => Opacity(
                opacity: pressed ? 0.6 : 1,
                child: VMono(_obscure ? l.authShow : l.authHide),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            key: const ValueKey('recover-strength'),
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 4,
                    color: i < strength ? c.accent : c.line,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _Requirement(text: l.recoverRuleLength, state: password.length >= 8),
          const SizedBox(height: 8),
          _Requirement(text: l.recoverRuleNumber, state: RegExp(r'\d').hasMatch(password)),
          const SizedBox(height: 8),
          _Requirement(
            key: const ValueKey('recover-rule-different'),
            text: l.recoverRuleDifferent,
            state: _different ?? false,
            failed: _different == false,
          ),
          const SizedBox(height: 26),
          LineField(
            label: l.recoverRepeatLabel,
            fieldKey: const ValueKey('recover-repeat-field'),
            controller: _repeat,
            focusNode: _repeatFocus,
            obscure: true,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            error: _repeatError,
            errorKey: const ValueKey('recover-repeat-error'),
            onChanged: (_) {
              if (_repeatError != null) setState(() => _repeatError = null);
            },
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      bottom: VPrimaryButton(
        key: const ValueKey('recover-save'),
        label: l.recoverSave,
        busy: _busy,
        onPressed: _save,
      ),
    );
  }
}

/// Un requisito de la contraseña: un check de énfasis si se cumple, un
/// círculo apagado si todavía no y, si falló, todo en rojo.
class _Requirement extends StatelessWidget {
  const _Requirement({super.key, required this.text, required this.state, this.failed = false});

  final String text;
  final bool state;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = failed ? c.danger : (state ? c.ink : c.ink4);
    return Row(
      children: [
        SizedBox(
          width: 11,
          height: 11,
          child: state
              ? VIconView(VIcon.check, size: 11, color: c.accentText)
              : Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: failed ? c.danger : c.ink4, width: 1.2),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: VText.ui(14, color: color))),
      ],
    );
  }
}

/// Listo: "Contraseña · Actualizada", un 10 enorme, "Todo listo, {nombre}"
/// y "Ir a Vinilo". La sesión ya está abierta: el botón solo cierra esta
/// pantalla.
class RecoverDoneScreen extends StatelessWidget {
  const RecoverDoneScreen({super.key, this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final first = (name ?? '').trim().split(RegExp(r'\s+')).first;
    final bottomPad = math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          VMono(l.recoverDoneLabel),
                          VMono(l.recoverDoneUpdated, color: c.accentText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      '10',
                      style: VText.display(128, weight: 900, height: 0.86, color: c.accentText),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      first.isEmpty ? l.recoverDoneTitleNoName : l.recoverDoneTitle(first),
                      key: const ValueKey('recover-done-title'),
                      style: VText.display(52, weight: 800, height: 0.88, tracking: 0),
                    ),
                    const SizedBox(height: 12),
                    Text(l.recoverDoneBody, style: VText.ui(15, height: 1.45, color: c.ink2)),
                    const SizedBox(height: 32),
                    const Spacer(),
                    VPrimaryButton.accent(
                      key: const ValueKey('recover-go'),
                      label: l.recoverGo,
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
