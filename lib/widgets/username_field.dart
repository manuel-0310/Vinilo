import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/username.dart';
import 'line_field.dart';
import 'v_icons.dart';
import 'v_sections.dart';

enum _Status { idle, current, invalid, checking, available, taken, offline }

/// Campo del @usuario (un `LineField` con "@" delante): pasa a minúsculas
/// mientras se escribe, valida las reglas al instante y, cuando el nombre es
/// válido, pregunta a Firestore si está libre (con un pequeño retraso para
/// no consultar en cada tecla). Junto a la etiqueta dice "✓ Disponible",
/// "Comprobando…" u "Ocupado"; lo que falla va debajo de la línea.
/// `onChanged` recibe el @usuario listo para reservar, o null si todavía no
/// sirve.
class UsernameField extends StatefulWidget {
  const UsernameField({
    super.key,
    required this.onChanged,
    this.initial = '',
    this.forUid,
    this.autofocus = false,
    this.onSubmitted,
    this.label,
    this.error,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
  });

  final ValueChanged<String?> onChanged;

  /// El @usuario actual de la persona: cuenta como disponible sin consultar.
  final String initial;
  final String? forUid;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  /// Etiqueta mono ("Usuario"); sin ella solo queda el estado.
  final String? label;

  /// Error que pone quien lo usa (por ejemplo, "Elige tu @usuario." al
  /// enviar vacío). Si la validación ya dice algo ("Ocupado", "Mínimo 3
  /// caracteres"), se ve eso.
  final String? error;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;

  @override
  State<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<UsernameField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  Timer? _debounce;
  _Status _status = _Status.idle;
  String _username = '';
  UsernameProblem? _problem;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      _status = _Status.current;
      _username = widget.initial;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _set(_Status status, {UsernameProblem? problem, String? valid}) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _problem = problem;
    });
    widget.onChanged(valid);
  }

  void _onText(String raw) {
    _debounce?.cancel();
    final username = normalizeUsername(raw);
    _username = username;
    final problem = usernameProblem(username);
    if (problem == UsernameProblem.empty) {
      _set(_Status.idle);
      return;
    }
    if (problem != null) {
      _set(_Status.invalid, problem: problem);
      return;
    }
    if (username == widget.initial) {
      _set(_Status.current, valid: username);
      return;
    }
    _set(_Status.checking);
    final id = ++_request;
    _debounce = Timer(const Duration(milliseconds: 450), () => _check(username, id));
  }

  Future<void> _check(String username, int id) async {
    final services = ServicesScope.of(context);
    try {
      final free = await services.users
          .isUsernameAvailable(username, forUid: widget.forUid);
      if (id != _request) return; // Ya se escribió otra cosa.
      if (free) {
        _set(_Status.available, valid: username);
      } else {
        _set(_Status.taken);
      }
    } catch (_) {
      if (id != _request) return;
      _set(_Status.offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final validation = switch (_status) {
      _Status.invalid => usernameProblemMessage(_problem!, l),
      _Status.taken => l.usernameTaken(_username),
      _Status.offline => l.usernameOffline,
      _ => null,
    };
    final Widget? status = switch (_status) {
      _Status.available => Row(
          key: const ValueKey('username-status'),
          mainAxisSize: MainAxisSize.min,
          children: [
            VIconView(VIcon.check, size: 10, color: c.success),
            const SizedBox(width: 5),
            VMono(l.usernameStatusAvailable, size: 10, color: c.success),
          ],
        ),
      _Status.checking => VMono(
          l.usernameStatusChecking,
          key: const ValueKey('username-status'),
          size: 10,
          color: c.ink4,
        ),
      _Status.taken => VMono(
          l.usernameStatusTaken,
          key: const ValueKey('username-status'),
          size: 10,
          color: c.danger,
        ),
      _ => null,
    };
    return LineField(
      label: widget.label,
      status: status,
      fieldKey: const ValueKey('username-field'),
      controller: _controller,
      focusNode: widget.focusNode,
      prefix: '@',
      hint: l.usernameHint,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.newUsername],
      inputFormatters: [
        const _UsernameFormatter(),
        LengthLimitingTextInputFormatter(usernameMax),
      ],
      onChanged: _onText,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      error: validation ?? widget.error,
    );
  }
}

/// Deja solo lo permitido en un @usuario y en minúsculas mientras se escribe.
class _UsernameFormatter extends TextInputFormatter {
  const _UsernameFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = stripUsername(newValue.text);
    if (cleaned == newValue.text) return newValue;
    // Cuántos caracteres antes del cursor sobrevivieron, para dejarlo ahí.
    final before = newValue.selection.baseOffset < 0
        ? cleaned.length
        : stripUsername(
            newValue.text.substring(
              0,
              newValue.selection.baseOffset.clamp(0, newValue.text.length),
            ),
          ).length;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: before.clamp(0, cleaned.length)),
    );
  }
}
