import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_service.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/sheet.dart';

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
      setState(() => _error = 'Escribe tu contraseña para confirmar.');
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
        _error = e is AccountDeletionException ? e.message : '$e';
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
    Widget item(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: c.text3),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: VText.ui(13, color: c.text2, height: 1.35)),
              ),
            ],
          ),
        );

    return PopScope(
      canPop: !_busy,
      child: SheetScaffold(
        title: 'Eliminar cuenta',
        subtitle: 'No se puede deshacer',
        // La hoja ya se desplaza, deja márgenes y sube con el teclado.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Se borra para siempre todo lo tuyo:',
              style: VText.ui(14, weight: 700),
            ),
            const SizedBox(height: 12),
            item(Icons.person_outline_rounded, 'Tu perfil, tu @usuario, tu foto y tu fondo.'),
            item(Icons.album_outlined, 'Tus notas y comentarios (los promedios de los discos se recalculan) y tus "me gusta".'),
            item(Icons.queue_music_rounded, 'Tus listas y las que guardaste.'),
            item(Icons.group_outlined, 'A quién sigues y quién te sigue.'),
            item(Icons.notifications_none_rounded, 'Tus notificaciones.'),
            const SizedBox(height: 10),
            Text(
              'Para confirmar, escribe tu contraseña.',
              style: VText.ui(13, color: c.text2),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('delete-password'),
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
              style: VText.ui(16, weight: 600),
              decoration: InputDecoration(
                hintText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: c.text3),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: c.text3,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                key: const ValueKey('delete-error'),
                style: VText.ui(13, weight: 600, color: c.danger, height: 1.35),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey('delete-confirm'),
              onPressed: _busy ? null : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: c.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: c.danger.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
              ),
              child: _busy
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Borrando tu cuenta…', style: VText.ui(16, weight: 700, color: Colors.white)),
                      ],
                    )
                  : const Text('Eliminar mi cuenta'),
            ),
            const SizedBox(height: 6),
            TextButton(
              key: const ValueKey('delete-cancel'),
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
              child: Text('Cancelar', style: VText.ui(15, weight: 700, color: c.text)),
            ),
          ],
        ),
      ),
    );
  }
}
