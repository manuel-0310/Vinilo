import 'dart:async';
import 'dart:io';

/// Si hay salida a internet: se abre (y se cierra) una conexión a los
/// servidores de Firebase. Un DNS en caché no basta para engañarla.
Future<bool> probeConnection() async {
  try {
    final socket = await Socket.connect(
      'firestore.googleapis.com',
      443,
      timeout: const Duration(seconds: 4),
    );
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
