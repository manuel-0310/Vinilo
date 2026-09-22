// Punto de entrada alterno para desarrollo: arranca Vinilo con la extensión
// de Flutter Driver activa, de modo que un script externo pueda tocar,
// escribir y desplazar la interfaz por el VM Service.
//
//   flutter run -t test_driver/app.dart -d <simulador> --dart-define=SPOTIFY_FN_URL=…
import 'package:flutter_driver/driver_extension.dart';
import 'package:no_retiene/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
