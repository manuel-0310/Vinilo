import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/account_service.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/line_field.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';

/// "Eliminar cuenta": explica qué se borra, avisa que no se puede deshacer y
/// pide la contraseña otra vez (Firebase exige un inicio de sesión reciente).
/// Al terminar cierra todo y la app vuelve a la bienvenida.
Future<void> showDeleteAccount(BuildContext context) {
  return showVSheet<void>(context, (_) => const _DeleteAccount());
}

class _DeleteAccount extends StatefulWidget {
  const _DeleteAccount();

  @override
  State<_DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<_DeleteAccount> {
  final _password = TextEditingController();
  late final AccountService _account;
  bool _busy = false;
  bool _done = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _account = ServicesScope.of(context).account;
  }

  @override
  void dispose() {
    // Si se cierra sin terminar (o tras un error), la app deja de sostener
    // el último perfil.
    if (!_done) _account.deleting = false;
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _error = context.l10n.deletePasswordMissing);
      return;
    }
    FocusScope.of(context).unfocus();
    HapticFeedback.heavyImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      await _account.deleteAccount(password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = describeError(e, context.l10n);
      });
      return;
    }
    _done = true;
    // Se quitan la hoja y las pantallas empujadas; al cerrarse la sesión
    // queda a la vista la bienvenida.
    navigator.popUntil((r) => r.isFirst);
    await _account.finish();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    Widget item(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(width: 4, height: 4, color: c.ink4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: VText.ui(13.5, color: c.ink2, height: 1.4)),
              ),
            ],
          ),
        );

    return PopScope(
      canPop: !_busy,
      child: SheetScaffold(
        title: l10n.deleteAccount,
        overline: l10n.deleteCannotUndo,
        titleSize: 40,
        // La hoja ya se desplaza, deja márgenes y sube con el teclado.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteIntro, style: VText.ui(14, weight: 600)),
            const SizedBox(height: 12),
            item(l10n.deleteItemProfile),
            item(l10n.deleteItemRatings),
            item(l10n.deleteItemLists),
            item(l10n.deleteItemFollows),
            item(l10n.deleteItemNotifications),
            const SizedBox(height: 18),
            LineField(
              label: l10n.deleteConfirmPrompt,
              fieldKey: const ValueKey('delete-password'),
              controller: _password,
              enabled: !_busy,
              obscure: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
              error: _error,
              errorKey: const ValueKey('delete-error'),
              trailing: Pressable(
                onTap: () => setState(() => _obscure = !_obscure),
                builder: (context, pressed) => Opacity(
                  opacity: pressed ? 0.6 : 1,
                  child: VMono(_obscure ? l10n.authShow : l10n.authHide),
                ),
              ),
            ),
            const SizedBox(height: 24),
            VPrimaryButton.tone(
              key: const ValueKey('delete-confirm'),
              label: _busy ? l10n.deleteInProgress : l10n.deleteConfirm,
              color: c.danger,
              busy: _busy,
              onPressed: _delete,
            ),
            const SizedBox(height: 8),
            VSecondaryButton(
              key: const ValueKey('delete-cancel'),
              label: l10n.cancel,
              center: true,
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
