/// En la web no hay sockets: se da por hecho que hay conexión (si no la
/// hay, lo dice cada petición que falla).
Future<bool> probeConnection() async => true;
