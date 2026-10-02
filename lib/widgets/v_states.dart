import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/support.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_ruler.dart';
import 'v_sections.dart';

/// "Sin conexión" (prototipo "Sin conexión" de `Vinilo Estados.dc.html`):
/// "Sin señal · Lado B" con una línea debajo, la gráfica plana de 120, el
/// título de 64, la explicación y, abajo, "Reintentar" (con "Conectando…"
/// mientras comprueba) y "Ver mis discos guardados". Llena el alto que le
/// den (va en un `SliverFillRemaining` o en una pantalla).
class OfflineState extends StatelessWidget {
  const OfflineState({
    super.key,
    required this.onRetry,
    this.checking = false,
    this.onSaved,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 38),
  });

  final VoidCallback onRetry;

  /// Mientras se comprueba la conexión: "Conectando…" con el spinner.
  final bool checking;

  /// "Ver mis discos guardados" (el diario, que vive en el teléfono). Sin
  /// él, no aparece.
  final VoidCallback? onSaved;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Padding(
      padding: padding,
      child: Column(
        key: const ValueKey('offline-state'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(
              children: [
                Expanded(child: VMono(l.offlineOverline)),
                VMono(l.offlineSide),
              ],
            ),
          ),
          const SizedBox(height: 60),
          const Histogram10(counts: {}, height: 120, barMargin: 1.5),
          const SizedBox(height: 28),
          Text(l.offlineTitle, style: VText.display(64, weight: 800, height: 0.86, tracking: 0)),
          const SizedBox(height: 12),
          Text(l.offlineBody, style: VText.ui(15, height: 1.45, color: c.ink2)),
          const SizedBox(height: 32),
          const Spacer(),
          VPrimaryButton(
            key: const ValueKey('offline-retry'),
            label: checking ? l.offlineConnecting : l.retry,
            trailingIcon: VIcon.refresh,
            busy: checking,
            onPressed: onRetry,
          ),
          if (onSaved != null) ...[
            const SizedBox(height: 8),
            VSecondaryButton(
              key: const ValueKey('offline-saved'),
              label: l.offlineSaved,
              onPressed: onSaved,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Se rayó el disco" (prototipo "Error servidor"): el estado en grande en
/// rojo, el título, la explicación, el código para citarlo
/// ("Código · VN-500-7F2A") y, abajo, "Intentar de nuevo" y "Reportar el
/// problema" (lo manda a `problems/`; si no se puede, copia el código y
/// dice a qué correo escribir). El código se saca una vez por error.
class ServerErrorState extends StatefulWidget {
  const ServerErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.retrying = false,
    this.where = '',
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 38),
  });

  final Object? error;
  final VoidCallback onRetry;
  final bool retrying;

  /// Dónde pasó ("search: radiohead"), para el reporte.
  final String where;
  final EdgeInsets padding;

  @override
  State<ServerErrorState> createState() => _ServerErrorStateState();
}

class _ServerErrorStateState extends State<ServerErrorState> {
  late String _code = errorCode(widget.error);
  bool _sending = false;
  bool _sent = false;

  @override
  void didUpdateWidget(ServerErrorState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.error, widget.error)) {
      _code = errorCode(widget.error);
      _sent = false;
    }
  }

  Future<void> _report() async {
    if (_sending || _sent) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final services = ServicesScope.of(context);
    final me = CurrentUser.maybeOf(context);
    setState(() => _sending = true);
    var ok = false;
    if (me != null) {
      try {
        await services.support
            .reportProblem(
              uid: me.uid,
              code: _code,
              detail: [widget.where, '${widget.error}'].where((s) => s.isNotEmpty).join(' · '),
            )
            .timeout(const Duration(seconds: 8));
        ok = true;
      } catch (_) {
        ok = false;
      }
    }
    if (!ok) await Clipboard.setData(ClipboardData(text: _code));
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
    HapticFeedback.lightImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(ok ? l.problemReported : l.problemCopied(supportEmail))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Padding(
      padding: widget.padding,
      child: Column(
        key: const ValueKey('server-error'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 50),
          Text(
            '${serverStatusOf(widget.error)}',
            maxLines: 1,
            style: VText.display(180, weight: 900, height: 0.8, tracking: 0, color: c.danger),
          ),
          const SizedBox(height: 22),
          Text(l.serverErrorTitle, style: VText.display(52, weight: 800, height: 0.88, tracking: 0)),
          const SizedBox(height: 12),
          Text(l.serverErrorBody, style: VText.ui(15, height: 1.45, color: c.ink2)),
          const SizedBox(height: 16),
          VMono(
            l.serverErrorCode(_code),
            key: const ValueKey('server-error-code'),
            size: 10,
            tracking: 0.06,
            color: c.inkA(0.4),
          ),
          const SizedBox(height: 32),
          const Spacer(),
          VPrimaryButton(
            key: const ValueKey('server-error-retry'),
            label: l.serverErrorRetry,
            trailingIcon: VIcon.refresh,
            busy: widget.retrying,
            onPressed: widget.onRetry,
          ),
          const SizedBox(height: 8),
          VSecondaryButton(
            key: const ValueKey('server-error-report'),
            label: l.serverErrorReport,
            busy: _sending,
            onPressed: _sent ? null : _report,
          ),
        ],
      ),
    );
  }
}

/// El aviso del inicio cuando se pierde la conexión (prototipo "Aviso sin
/// conexión"): una franja de tinta con "Sin conexión · mostrando lo último
/// guardado" y "Reintentar" (un spinner mientras comprueba).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRetry, this.checking = false});

  final VoidCallback onRetry;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Pressable(
      key: const ValueKey('offline-banner'),
      onTap: checking ? null : onRetry,
      builder: (context, pressed) => Container(
        color: c.ink,
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.offlineBanner,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VText.ui(14, weight: 600, color: c.bg),
              ),
            ),
            const SizedBox(width: 12),
            if (checking)
              VSpinner(size: 12, color: c.bg)
            else
              Opacity(
                opacity: pressed ? 0.6 : 1,
                child: VMono(l.retry, tracking: 0.06, color: c.bg),
              ),
          ],
        ),
      ),
    );
  }
}

/// Escucha la conexión (`Services.connectivity`) y reconstruye con ella.
class ConnectivityBuilder extends StatelessWidget {
  const ConnectivityBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool offline, bool checking) builder;

  @override
  Widget build(BuildContext context) {
    final connectivity = ServicesScope.of(context).connectivity;
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => builder(context, connectivity.offline, connectivity.checking),
    );
  }
}

/// Comprueba la conexión ahora (los "Reintentar").
void checkConnection(BuildContext context) =>
    unawaited(ServicesScope.of(context).connectivity.check());
