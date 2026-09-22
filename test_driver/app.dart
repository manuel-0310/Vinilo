// Punto de entrada alterno para desarrollo: arranca Vinilo con la extensión
// de Flutter Driver activa, de modo que un script externo pueda tocar,
// escribir y desplazar la interfaz por el VM Service.
//
//   flutter run -t test_driver/app.dart -d <simulador> --dart-define=SPOTIFY_FN_URL=…
//
// Mensajes (requestData) que entiende:
//   "tab:N"       cambia de pestaña (la barra nativa de iOS 26 no tiene finders)
//   "banner:URL"  fija la foto de fondo del perfil actual ("banner:" la quita),
//                 porque el driver no puede manejar la galería nativa.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:no_retiene/main.dart' as app;
import 'package:no_retiene/screens/shell_screen.dart';

void main() {
  enableFlutterDriverExtension(handler: (message) async {
    if (message != null && message.startsWith('tab:')) {
      ShellScreen.tabRequests.value = int.tryParse(message.substring(4));
      return 'ok';
    }
    if (message != null && message.startsWith('banner:')) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'no-user';
      final url = message.substring(7);
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'bannerUrl': url.isEmpty ? null : url},
        SetOptions(merge: true),
      );
      return 'ok';
    }
    return 'unknown';
  });
  app.main();
}
