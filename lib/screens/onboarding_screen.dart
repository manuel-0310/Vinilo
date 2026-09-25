import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../widgets/auth_page.dart';
import '../widgets/line_field.dart';
import '../widgets/username_field.dart';
import '../widgets/v_buttons.dart';
import 'sign_up_screen.dart';

/// Perfil de una cuenta que existe sin él (si el @usuario se lo llevó
/// alguien justo al crearla, o una cuenta de antes): con el mismo aspecto
/// que Crear cuenta, pide solo el nombre y el @usuario. El color arranca en
/// el de por defecto y la foto se pone después.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.uid});

  final String uid;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  String? _username;
  bool _busy = false;
  String? _nameError;
  String? _usernameError;

  @override
  void dispose() {
    _name.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = context.l10n;
    final name = _name.text.trim();
    final username = _username;
    setState(() {
      _nameError = name.isEmpty ? l.authNameMissing : null;
      _usernameError = username == null ? l.usernameEmpty : null;
    });
    if (username == null || _nameError != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ServicesScope.of(context).users.create(
            uid: widget.uid,
            name: name,
            username: username,
            colorValue: ViniloPalette.defaultAccent.toARGB32(),
          );
      // El perfil aparece y main pasa a la app.
    } catch (e) {
      if (mounted) setState(() => _usernameError = friendlyError(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = ServicesScope.of(context);
    final email = services.auth.email;
    return AuthScaffold(
      showBack: false,
      title: l.onboardingTitle,
      bodyTop: 16,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthParagraph(l.onboardingBody),
          const SizedBox(height: 28),
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
            forUid: widget.uid,
            focusNode: _usernameFocus,
            error: _usernameError,
            onChanged: (v) => setState(() {
              _username = v;
              _usernameError = null;
            }),
            onSubmitted: _submit,
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VPrimaryButton(
            key: const ValueKey('profile-submit'),
            label: l.onboardingStart,
            busy: _busy,
            onPressed: _submit,
          ),
          if (email != null) ...[
            const SizedBox(height: 14),
            AuthSwitchLine(
              key: const ValueKey('onboarding-signout'),
              question: l.onboardingSignedInAs(email),
              action: l.onboardingSignOut,
              onTap: services.auth.signOut,
            ),
          ],
        ],
      ),
    );
  }
}
