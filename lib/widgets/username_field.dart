import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/username.dart';

enum _Status { idle, invalid, checking, available, taken, offline }

/// Campo del @usuario: pasa a minúsculas mientras se escribe, valida las
/// reglas al instante y, cuando el nombre es válido, pregunta a Firestore si
/// está libre (con un pequeño retraso para no consultar en cada tecla).
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
  });

  final ValueChanged<String?> onChanged;

  /// El @usuario actual de la persona: cuenta como disponible sin consultar.
  final String initial;
  final String? forUid;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  State<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<UsernameField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  Timer? _debounce;
  _Status _status = _Status.idle;
  String _message = '';
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      _status = _Status.available;
      _message = 'Ese es tu @usuario actual.';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _set(_Status status, String message, {String? valid}) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _message = message;
    });
    widget.onChanged(valid);
  }

  void _onText(String raw) {
    _debounce?.cancel();
    final username = normalizeUsername(raw);
    final problem = usernameProblem(username);
    if (problem == UsernameProblem.empty) {
      _set(_Status.idle, '');
      return;
    }
    if (problem != null) {
      _set(_Status.invalid, usernameProblemMessage(problem));
      return;
    }
    if (username == widget.initial) {
      _set(_Status.available, 'Ese es tu @usuario actual.', valid: username);
      return;
    }
    _set(_Status.checking, 'Comprobando…');
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
        _set(_Status.available, '@$username está libre.', valid: username);
      } else {
        _set(_Status.taken, '@$username ya está en uso. Prueba con otro.');
      }
    } catch (_) {
      if (id != _request) return;
      _set(_Status.offline, 'No se pudo comprobar. Revisa tu conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final statusColor = switch (_status) {
      _Status.available => c.success,
      _Status.invalid || _Status.taken || _Status.offline => c.danger,
      _ => c.text3,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('username-field'),
          controller: _controller,
          autofocus: widget.autofocus,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            const _UsernameFormatter(),
            LengthLimitingTextInputFormatter(usernameMax),
          ],
          onChanged: _onText,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          style: VText.ui(17, weight: 600),
          decoration: InputDecoration(
            hintText: 'tu_usuario',
            prefixText: '@',
            prefixStyle: VText.ui(17, weight: 600, color: c.text2),
            suffixIcon: _SuffixFor(status: _status),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _message.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                  child: Text(
                    _message,
                    key: const ValueKey('username-status'),
                    style: VText.ui(12, weight: 600, color: statusColor),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SuffixFor extends StatelessWidget {
  const _SuffixFor({required this.status});

  final _Status status;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return switch (status) {
      _Status.checking => Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.text3),
          ),
        ),
      _Status.available => Icon(Icons.check_circle_rounded, color: c.success),
      _Status.taken ||
      _Status.invalid ||
      _Status.offline =>
        Icon(Icons.error_rounded, color: c.danger),
      _Status.idle => const SizedBox.shrink(),
    };
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
