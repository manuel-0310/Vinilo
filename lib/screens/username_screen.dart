import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../util/username.dart';
import '../widgets/auth_page.dart';
import '../widgets/user_avatar.dart';
import '../widgets/username_field.dart';

/// Elegir el @usuario cuando el perfil ya existe pero todavía no lo tiene
/// (las cuentas guardadas desde una sesión anónima).
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
    final username = _username;
    if (username == null || _busy) return;
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
    final c = VColors.of(context);
    final profile = widget.profile;
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
            TextSpan(text: context.l10n.usernameTitleStart),
            TextSpan(
              text: context.l10n.usernameTitleAccent,
              style: VText.display(42, italic: true, color: c.accent),
            ),
            TextSpan(text: context.l10n.usernameTitleEnd),
          ],
        ),
      ),
      subtitle: context.l10n.usernameSubtitle(usernameMin, usernameMax),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UsernameField(
            autofocus: true,
            forUid: profile.uid,
            onChanged: (v) => setState(() {
              _username = v;
              _error = null;
            }),
            onSubmitted: _save,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
              child: Text(
                _error!,
                key: const ValueKey('username-error'),
                style: VText.ui(13, weight: 600, color: c.danger),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('username-submit'),
            onPressed: _username == null || _busy ? null : _save,
            child: _busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.onAccent,
                    ),
                  )
                : Text(context.l10n.continueLabel),
          ),
        ],
      ),
    );
  }
}
