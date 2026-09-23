import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_repo.dart';

const String genericAuthMessage = 'Algo falló. Vuelve a intentarlo.';

/// Mensaje en español para un código de `FirebaseAuthException`.
String authMessageForCode(String code) => switch (code) {
      'email-already-in-use' =>
        'Ese correo ya tiene una cuenta. Inicia sesión o usa otro.',
      'invalid-email' || 'missing-email' => 'Ese correo no parece válido.',
      'weak-password' =>
        'La contraseña es muy débil: usa al menos 6 caracteres.',
      'missing-password' => 'Escribe tu contraseña.',
      // Con la protección contra enumeración de correos, Firebase responde
      // lo mismo si el correo no existe o si la contraseña está mal.
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'Correo o contraseña incorrectos.',
      'user-disabled' => 'Esta cuenta está deshabilitada.',
      'too-many-requests' =>
        'Demasiados intentos. Espera un momento y vuelve a probar.',
      'network-request-failed' =>
        'Sin conexión. Revisa tu internet y vuelve a intentar.',
      'operation-not-allowed' =>
        'El acceso con correo y contraseña no está habilitado todavía.',
      'credential-already-in-use' =>
        'Ese correo ya pertenece a otra cuenta. Inicia sesión con ella o usa otro correo.',
      'provider-already-linked' => 'Esta sesión ya tiene un correo vinculado.',
      'requires-recent-login' =>
        'Por seguridad, vuelve a iniciar sesión antes de hacer esto.',
      'user-token-expired' || 'invalid-user-token' =>
        'Tu sesión venció. Vuelve a iniciar sesión.',
      _ => genericAuthMessage,
    };

/// Mensaje claro para cualquier error que pueda salir al entrar, crear la
/// cuenta o guardar el perfil.
String friendlyError(Object error) {
  if (error is FirebaseAuthException) return authMessageForCode(error.code);
  if (error is UsernameTakenException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'No tienes permiso para hacer eso.',
      'unavailable' || 'network-request-failed' =>
        'Sin conexión. Revisa tu internet y vuelve a intentar.',
      _ => genericAuthMessage,
    };
  }
  return genericAuthMessage;
}
