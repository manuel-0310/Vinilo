import 'dart:async';

import '../util/errors.dart';
import 'connectivity_service.dart';

/// Sube la cola de notas sin conexión (`users/{uid}/outbox`) en cuanto se
/// puede: al arrancar, cuando llega algo nuevo a la cola y cuando vuelve la
/// conexión. Si la subida falla por la red, avisa a `connectivity` (que
/// vuelve a comprobar sola); en cualquier caso lo reintenta pasado
/// `retryAfter` (cada vez más espaciado). Nunca hay dos subidas a la vez.
class OutboxSync {
  OutboxSync({
    required this.connectivity,
    required Stream<int> pendingCount,
    required Future<int> Function() flush,
    this.retryAfter = const Duration(seconds: 30),
  })  : _pendingCount = pendingCount,
        _flush = flush;

  final ConnectivityService connectivity;
  final Stream<int> _pendingCount;
  final Future<int> Function() _flush;
  final Duration retryAfter;

  StreamSubscription<int>? _sub;
  Timer? _retry;
  int _pending = 0;
  bool _running = false;
  bool _dirty = false;
  bool _wasOnline = true;
  bool _disposed = false;

  /// Fallos seguidos: cada uno duplica la espera del reintento (hasta 32
  /// veces `retryAfter`), así un error que no se arregla solo no insiste.
  int _failures = 0;

  /// Cuántas notas esperan (lo último que dijo la cola).
  int get pending => _pending;

  void start() {
    _wasOnline = connectivity.online;
    connectivity.addListener(_onConnectivity);
    _sub = _pendingCount.listen((n) {
      _pending = n;
      if (_running) {
        _dirty = true;
      } else {
        unawaited(_maybeFlush());
      }
    }, onError: (Object _) {});
  }

  void _onConnectivity() {
    final online = connectivity.online;
    final cameBack = online && !_wasOnline;
    _wasOnline = online;
    if (cameBack) unawaited(_maybeFlush());
  }

  Future<void> _maybeFlush() async {
    if (_disposed || _running || _pending == 0 || connectivity.offline) return;
    _running = true;
    _dirty = false;
    _retry?.cancel();
    var failed = false;
    try {
      await _flush();
      _failures = 0;
      connectivity.reportSuccess();
    } catch (e) {
      failed = true;
      if (isOfflineError(e)) connectivity.reportFailure();
      // Si de verdad no hay conexión, la vuelta la da `_onConnectivity`;
      // si la hay (un corte de un momento, un error del servidor), este
      // reintento.
      if (!_disposed) {
        _retry = Timer(retryAfter * (1 << _failures.clamp(0, 5)), () => unawaited(_maybeFlush()));
      }
      _failures++;
    } finally {
      _running = false;
    }
    // Llegó algo a la cola mientras se subía: otra vuelta.
    if (!failed && _dirty) unawaited(_maybeFlush());
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    connectivity.removeListener(_onConnectivity);
    unawaited(_sub?.cancel());
  }
}
