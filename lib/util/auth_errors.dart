import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/l10n.dart';
import '../services/user_repo.dart';

/// Mensaje para un código de `FirebaseAuthException`, en el idioma de la app.
String authMessageForCode(String code, AppLocalizations l) => switch (code) {
      'email-already-in-use' => l.authEmailInUse,
      'invalid-email' || 'missing-email' => l.authInvalidEmail,
      'weak-password' => l.authWeakPassword,
      'missing-password' => l.authMissingPassword,
      // Con la protección contra enumeración de correos, Firebase responde
      // lo mismo si el correo no existe o si la contraseña está mal.
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        l.authWrongCredentials,
      'user-disabled' => l.authUserDisabled,
      'too-many-requests' => l.authTooManyRequests,
      'network-request-failed' => l.errorOffline,
      'operation-not-allowed' => l.authOperationNotAllowed,
      'credential-already-in-use' => l.authCredentialInUse,
      'provider-already-linked' => l.authProviderLinked,
      'requires-recent-login' => l.authRequiresRecentLogin,
      'user-token-expired' || 'invalid-user-token' => l.authSessionExpired,
      _ => l.errorGeneric,
    };

/// Mensaje claro para cualquier error que pueda salir al entrar, crear la
/// cuenta o guardar el perfil.
String friendlyError(Object error, AppLocalizations l) {
  if (error is FirebaseAuthException) return authMessageForCode(error.code, l);
  if (error is UsernameTakenException) return l.usernameTaken(error.username);
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => l.errorPermissionDenied,
      'unavailable' || 'network-request-failed' => l.errorOffline,
      _ => l.errorGeneric,
    };
  }
  return l.errorGeneric;
}
