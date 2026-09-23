import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// El borrado no se pudo completar; `message` ya viene en español para
/// mostrarlo tal cual.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Borrar la cuenta. Lo hace la Cloud Function `account` con el Admin SDK
/// (perfil, @usuario, fotos, notas con sus agregados, likes, listas,
/// seguimientos con sus contadores, notificaciones y la cuenta de Auth), así
/// nada queda a medias si la app se cierra en mitad del proceso.
class AccountService {
  AccountService({required AuthService auth, required String spotifyUrl})
      : _auth = auth,
        _endpoint = endpointFrom(
          override: const String.fromEnvironment('ACCOUNT_FN_URL'),
          spotifyUrl: spotifyUrl,
        );

  final AuthService _auth;
  final Uri? _endpoint;

  /// True mientras se borra: `main.dart` sigue mostrando la app con el último
  /// perfil aunque su documento ya no exista, hasta que se cierre la sesión.
  bool deleting = false;

  /// La función vive junto a la de Spotify: `…/spotify` → `…/account`.
  /// `ACCOUNT_FN_URL` la fija a mano si algún día cambia de sitio.
  static Uri? endpointFrom({required String override, required String spotifyUrl}) {
    if (override.isNotEmpty) return Uri.parse(override);
    if (spotifyUrl.isEmpty) return null;
    final uri = Uri.parse(spotifyUrl);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.last != 'spotify') return null;
    segments[segments.length - 1] = 'account';
    return uri.replace(pathSegments: segments);
  }

  /// Vuelve a comprobar la contraseña (Firebase exige un inicio de sesión
  /// reciente) y pide el borrado. Si termina bien, la cuenta ya no existe:
  /// quien llama cierra las pantallas y llama a [finish].
  Future<void> deleteAccount(String password) async {
    final endpoint = _endpoint;
    if (endpoint == null) {
      throw const AccountDeletionException(
        'Falta la URL de la función (--dart-define=SPOTIFY_FN_URL=…).',
      );
    }
    try {
      await _auth.reauthenticate(password);
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(switch (e.code) {
        'wrong-password' ||
        'invalid-credential' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          'La contraseña no es correcta.',
        'too-many-requests' =>
          'Demasiados intentos. Espera un momento y vuelve a probar.',
        'network-request-failed' =>
          'Sin conexión. Revisa tu internet y vuelve a intentar.',
        _ => 'No se pudo comprobar tu contraseña (${e.code}).',
      });
    }
    final token = await _auth.current?.getIdToken(true);
    if (token == null) {
      throw const AccountDeletionException('No hay sesión.');
    }

    deleting = true;
    final http.Response res;
    try {
      res = await http
          .post(
            endpoint.replace(path: '${endpoint.path}/delete'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(minutes: 3));
    } on TimeoutException {
      throw const AccountDeletionException(
        'El borrado está tardando más de la cuenta. Vuelve a intentarlo: retoma donde quedó.',
      );
    } catch (_) {
      throw const AccountDeletionException(
        'Sin conexión. Revisa tu internet y vuelve a intentar.',
      );
    }
    if (res.statusCode == 200) return;
    String? message;
    try {
      message = (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String?;
    } catch (_) {}
    throw AccountDeletionException(
      message == null || message.isEmpty
          ? 'No se pudo borrar la cuenta (${res.statusCode}). Vuelve a intentarlo.'
          : message,
    );
  }

  /// Después de borrar: cierra la sesión (la app vuelve a la bienvenida).
  Future<void> finish() async {
    try {
      await _auth.signOut();
    } finally {
      deleting = false;
    }
  }
}
