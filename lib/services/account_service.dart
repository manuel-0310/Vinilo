import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import 'auth_service.dart';

/// Por qué no se pudo borrar la cuenta. La pantalla lo traduce con
/// [message]; `detail` lleva el código o el estado HTTP para depurar.
enum AccountDeletionError {
  noEndpoint,
  wrongPassword,
  tooManyRequests,
  offline,
  reauthFailed,
  noSession,
  timeout,
  requiresRecentLogin,
  server,
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.error, [this.detail]);

  final AccountDeletionError error;
  final String? detail;

  String message(AppLocalizations l) => switch (error) {
        AccountDeletionError.noEndpoint => l.deleteErrorNoEndpoint,
        AccountDeletionError.wrongPassword => l.deleteErrorWrongPassword,
        AccountDeletionError.tooManyRequests => l.authTooManyRequests,
        AccountDeletionError.offline => l.errorOffline,
        AccountDeletionError.reauthFailed => l.deleteErrorReauth(detail ?? ''),
        AccountDeletionError.noSession => l.deleteErrorNoSession,
        AccountDeletionError.timeout => l.deleteErrorTimeout,
        AccountDeletionError.requiresRecentLogin => l.deleteErrorRecentLogin,
        AccountDeletionError.server => l.deleteErrorServer(detail ?? ''),
      };

  @override
  String toString() => 'AccountDeletionException($error, $detail)';
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
      throw const AccountDeletionException(AccountDeletionError.noEndpoint);
    }
    try {
      await _auth.reauthenticate(password);
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(
        switch (e.code) {
          'wrong-password' ||
          'invalid-credential' ||
          'INVALID_LOGIN_CREDENTIALS' =>
            AccountDeletionError.wrongPassword,
          'too-many-requests' => AccountDeletionError.tooManyRequests,
          'network-request-failed' => AccountDeletionError.offline,
          _ => AccountDeletionError.reauthFailed,
        },
        e.code,
      );
    }
    final token = await _auth.current?.getIdToken(true);
    if (token == null) {
      throw const AccountDeletionException(AccountDeletionError.noSession);
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
      throw const AccountDeletionException(AccountDeletionError.timeout);
    } catch (_) {
      throw const AccountDeletionException(AccountDeletionError.offline);
    }
    if (res.statusCode == 200) return;
    // La función devuelve un `code` estable; el texto lo pone la app.
    String? code;
    try {
      code = (jsonDecode(res.body) as Map<String, dynamic>)['code'] as String?;
    } catch (_) {}
    throw AccountDeletionException(
      code == 'requires-recent-login'
          ? AccountDeletionError.requiresRecentLogin
          : AccountDeletionError.server,
      '${res.statusCode}',
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
