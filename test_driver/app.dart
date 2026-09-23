// Punto de entrada alterno para desarrollo: arranca Vinilo con la extensión
// de Flutter Driver activa, de modo que un script externo pueda tocar,
// escribir y desplazar la interfaz por el VM Service.
//
//   flutter run -t test_driver/app.dart -d <simulador> --dart-define=SPOTIFY_FN_URL=…
//
// Mensajes (requestData) que entiende:
//   "tab:N"         cambia de pestaña (la barra nativa de iOS 26 no tiene finders)
//   "banner:URL"    fija la foto de fondo del perfil actual ("banner:" la quita),
//                   porque el driver no puede manejar la galería nativa.
//   "comments:ALBUM_ID" abre la pantalla de todos los comentarios de un disco.
//   "crop-avatar:URL" / "crop-banner:URL"
//                   descarga la imagen y abre el recortador como si viniera de
//                   la galería; al confirmar, sube el resultado a Storage y lo
//                   guarda en el perfil (el mismo camino que la edición real).
//   "auth"          uid, correo, si es anónima y proveedores de la sesión.
//   "signout"       cierra la sesión (vuelve a la bienvenida).
//   "anon-with-profile"
//                   crea una sesión anónima con un perfil de prueba, como las
//                   que quedaron de antes, para probar "Guarda tu cuenta".
//   "delete-test-account"
//                   borra la cuenta actual con su perfil y su @usuario. Solo
//                   acepta correos @vinilo.test o la sesión anónima de prueba:
//                   nunca la cuenta de Manuel.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:http/http.dart' as http;
import 'package:no_retiene/main.dart' as app;
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/screens/profile_form.dart';
import 'package:no_retiene/screens/routes.dart';
import 'package:no_retiene/screens/shell_screen.dart';
import 'package:no_retiene/widgets/image_cropper.dart';

Future<String> _crop(String url, {required bool avatar}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return 'no-user';
  final res = await http.get(Uri.parse(url));
  if (res.statusCode != 200) return 'download-${res.statusCode}';
  // El shell ejecuta la acción con su contexto; no se espera el resultado:
  // el driver sigue mandando toques mientras el recortador está abierto y
  // el resultado se sube al confirmar.
  ShellScreen.actionRequests.value = (context) async {
    final bytes = await showImageCropper(
      context,
      bytes: res.bodyBytes,
      aspectRatio: avatar ? 1 : bannerAspect,
      outputWidth: avatar ? avatarSize : bannerWidth,
      circle: avatar,
      title: avatar ? 'Tu foto de perfil' : 'Tu foto de fondo',
    );
    if (bytes == null) return;
    final storage = FirebaseStorage.instance
        .ref(avatar ? 'avatars/$uid.jpg' : 'banners/$uid.jpg');
    await storage.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final download = await storage.getDownloadURL();
    // ignore: avoid_print
    print('CROP_RESULT ${avatar ? 'avatar' : 'banner'} bytes=${bytes.length} url=$download');
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {avatar ? 'avatarUrl' : 'bannerUrl': download},
      SetOptions(merge: true),
    );
  };
  return 'ok';
}

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
    if (message == 'auth') {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'no-user';
      final providers = user.providerData.map((p) => p.providerId).join(',');
      return 'uid=${user.uid} email=${user.email} anonymous=${user.isAnonymous} providers=$providers';
    }
    if (message == 'signout') {
      await FirebaseAuth.instance.signOut();
      return 'ok';
    }
    if (message == 'anon-with-profile') {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) await auth.signOut();
      final cred = await auth.signInAnonymously();
      final uid = cred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': 'Prueba Anónima',
        'color': 0xFF5FA8D3,
        'avatarUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'ratingsCount': 0,
        'ratingsSum': 0,
        'favorites': <Map<String, dynamic>>[],
        'recentSearches': <String>[],
      });
      return 'uid=$uid';
    }
    if (message == 'delete-test-account') {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'no-user';
      final users = FirebaseFirestore.instance.collection('users');
      final doc = await users.doc(user.uid).get();
      final name = doc.data()?['name'];
      final email = user.email ?? '';
      final isTest = email.endsWith('@vinilo.test') ||
          (user.isAnonymous && name == 'Prueba Anónima');
      if (!isTest) return 'refused: email=$email name=$name';
      final username = doc.data()?['username'] as String?;
      if (username != null) {
        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(username)
            .delete();
      }
      if (doc.exists) await users.doc(user.uid).delete();
      await user.delete();
      return 'deleted uid=${user.uid} username=$username';
    }
    if (message == 'whoami') {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'no-user';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        return 'uid=${user.uid} doc=${doc.data()}';
      } catch (e) {
        return 'uid=${user.uid} doc-error=$e';
      }
    }
    if (message != null && message.startsWith('comments:')) {
      // "comments:latest" usa el último disco que calificó esta persona.
      var id = message.substring(9);
      var album = Album(id: id, name: 'Disco', artist: '');
      if (id == 'latest') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final snap = await FirebaseFirestore.instance
            .collection('ratings')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) return 'no-ratings';
        final d = snap.docs.first.data();
        id = d['albumId'] as String;
        album = Album.fromMap(Map<String, dynamic>.from(d['album'] as Map));
      }
      final target = album;
      ShellScreen.actionRequests.value = (context) => openComments(
            context,
            album: target,
            initial: const [],
          );
      return 'ok';
    }
    if (message != null && message.startsWith('crop-avatar:')) {
      return _crop(message.substring(12), avatar: true);
    }
    if (message != null && message.startsWith('crop-banner:')) {
      return _crop(message.substring(12), avatar: false);
    }
    return 'unknown';
  });
  app.main();
}
