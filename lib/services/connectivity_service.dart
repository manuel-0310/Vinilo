import 'dart:async';

import 'package:flutter/foundation.dart';

import 'probe/probe_web.dart' if (dart.library.io) 'probe/probe_io.dart';

/// Si la app tiene conexión, sin paquetes nativos: lo comprueba al arrancar
/// y al volver al frente, cuando alguna petición falla por la red
/// (`reportFailure`) y, mientras esté sin conexión, cada pocos segundos
/// hasta que vuelva. Las pantallas lo escuchan (es un `Listenable`) para
/// mostrar el aviso de "Sin conexión" y la cola de notas lo usa para saber
/// cuándo subirlas.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({
    Future<bool> Function()? probe,
    this.retryEvery = const Duration(seconds: 6),
  }) : _probe = probe ?? probeConnection;

  final Future<bool> Function() _probe;

  /// Cada cuánto se vuelve a comprobar mientras no hay conexión.
  final Duration retryEvery;

  bool _online = true;
  bool _checking = false;
  bool _disposed = false;
  Timer? _retry;
  Future<bool>? _running;

  /// Con conexión (se supone que sí hasta que algo diga lo contrario).
  bool get online => _online;
  bool get offline => !_online;

  /// Hay una comprobación en curso ("Conectando…").
  bool get checking => _checking;

  /// Comprueba ahora. Si ya hay una comprobación en curso, espera esa.
  Future<bool> check() {
    return _running ??= _check().whenComplete(() => _running = null);
  }

  Future<bool> _check() async {
    _checking = true;
    _notify();
    bool ok;
    try {
      ok = await _probe();
    } catch (_) {
      ok = false;
    }
    _checking = false;
    _set(ok, force: true);
    return ok;
  }

  /// Una petición falló por la red: se comprueba si de verdad no hay
  /// conexión.
  void reportFailure() {
    if (_disposed) return;
    unawaited(check());
  }

  /// Una petición a internet salió bien: hay conexión.
  void reportSuccess() => _set(true);

  void _set(bool online, {bool force = false}) {
    if (_disposed) return;
    final changed = online != _online;
    _online = online;
    _retry?.cancel();
    _retry = null;
    if (!online) {
      _retry = Timer(retryEvery, () {
        if (!_disposed) unawaited(check());
      });
    }
    if (changed || force) _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    super.dispose();
  }
}
