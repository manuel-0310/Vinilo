import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../util/auth_errors.dart';
import '../util/username.dart';
import '../widgets/auth_page.dart';
import '../widgets/username_field.dart';
import '../widgets/v_buttons.dart';

/// Elegir el @usuario cuando el perfil ya existe pero todavía no lo tiene
/// (las cuentas guardadas desde una sesión anónima). Sin diseño propio: el
/// mismo andamio que Crear cuenta.
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  String? _username;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_busy) return;
    final username = _username;
    if (username == null) {
      setState(() => _error = context.l10n.usernameEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ServicesScope.of(context).users.setUsername(
            widget.profile.uid,
            username,
            previous: widget.profile.username,
          );
      // El perfil cambia y main pasa al shell.
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      showBack: false,
      title: l.usernameTitle,
      bodyTop: 16,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthParagraph(l.usernameSubtitle(usernameMin, usernameMax)),
          const SizedBox(height: 28),
          UsernameField(
            label: l.authUsernameLabel,
            autofocus: true,
            forUid: widget.profile.uid,
            error: _error,
            onChanged: (v) => setState(() {
              _username = v;
              _error = null;
            }),
            onSubmitted: _save,
          ),
        ],
      ),
      bottom: VPrimaryButton(
        key: const ValueKey('username-submit'),
        label: l.continueLabel,
        busy: _busy,
        onPressed: _save,
      ),
    );
  }
}
