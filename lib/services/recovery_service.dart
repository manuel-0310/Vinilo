import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import '../util/function_url.dart';

/// Qué pasó al recuperar la contraseña. `notAvailable` es que la función
/// `recover` no está desplegada o no tiene correo configurado: entonces la
/// app manda el enlace de Firebase de siempre.
enum RecoveryError {
  notAvailable,
  invalidEmail,
  throttled,
  wrongCode,
  tooManyAttempts,
  expired,
  weakPassword,
  offline,
  server,
}

class RecoveryException implements Exception {
  const RecoveryException(this.error, {this.left, this.retryAfter});

  final RecoveryError error;

  /// Con `wrongCode`, cuántos intentos quedan.
  final int? left;

  /// Con `throttled`, cuántos segundos hay que esperar.
  final int? retryAfter;

  String message(AppLocalizations l) => switch (error) {
        RecoveryError.invalidEmail => l.authInvalidEmail,
        RecoveryError.throttled => l.recoverThrottled(retryAfter ?? 45),
        RecoveryError.wrongCode => l.recoverWrongCode(left ?? 0),
        RecoveryError.tooManyAttempts => l.recoverTooMany,
        RecoveryError.expired => l.recoverExpired,
        RecoveryError.weakPassword => l.recoverWeak,
        RecoveryError.offline => l.errorOffline,
        RecoveryError.notAvailable || RecoveryError.server => l.recoverServer,
      };

  @override
  String toString() => 'RecoveryException($error, left: $left, retryAfter: $retryAfter)';
}

/// Recuperar la contraseña con un código de 6 dígitos: habla con la función
/// `recover` (junto a la de Spotify: `…/spotify` → `…/recover`), que manda
/// el código por correo, lo comprueba y cambia la contraseña.
class RecoveryService {
  RecoveryService({required String spotifyUrl, http.Client? client})
      : _endpoint = endpointFrom(
          override: const String.fromEnvironment('RECOVER_FN_URL'),
          spotifyUrl: spotifyUrl,
        ),
        _client = client ?? http.Client();

  /// Para las pruebas: con la URL ya resuelta.
  RecoveryService.at(Uri? endpoint, {http.Client? client})
      : _endpoint = endpoint,
        _client = client ?? http.Client();

  final Uri? _endpoint;
  final http.Client _client;

  static Uri? endpointFrom({required String override, required String spotifyUrl}) {
    if (override.isNotEmpty) return Uri.parse(override);
    return siblingFunctionUrl(spotifyUrl, 'recover');
  }

  /// Pide el código. Devuelve en cuántos segundos se puede pedir otro.
  Future<int> start(String email, {required String lang}) async {
    final body = await _post('start', {'email': email.trim(), 'lang': lang});
    return (body['resendIn'] as num?)?.toInt() ?? 45;
  }

  /// Comprueba el código. Devuelve el ticket con el que se cambia la
  /// contraseña.
  Future<String> verify(String email, String code) async {
    final body = await _post('verify', {'email': email.trim(), 'code': code});
    final ticket = body['ticket'];
    if (ticket is! String || ticket.isEmpty) {
      throw const RecoveryException(RecoveryError.server);
    }
    return ticket;
  }

  /// Cambia la contraseña. Devuelve el nombre de la persona (o null).
  Future<String?> finish(String email, {required String ticket, required String password}) async {
    final body = await _post('finish', {
      'email': email.trim(),
      'ticket': ticket,
      'password': password,
    });
    return body['name'] as String?;
  }

  /// Si `password` es la contraseña que la cuenta ya tiene ("Distinta a la
  /// anterior"): se prueba a entrar con ella por la API de Firebase Auth,
  /// sin tocar la sesión de la app. Ante la duda (sin red, otro error), no.
  Future<bool> isCurrentPassword({
    required String email,
    required String password,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) return false;
    try {
      final res = await _client
          .post(
            Uri.https(
              'identitytoolkit.googleapis.com',
              '/v1/accounts:signInWithPassword',
              {'key': apiKey},
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'returnSecureToken': false,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post(String route, Map<String, dynamic> payload) async {
    final endpoint = _endpoint;
    if (endpoint == null) throw const RecoveryException(RecoveryError.notAvailable);
    final http.Response res;
    try {
      res = await _client
          .post(
            endpoint.replace(path: '${endpoint.path}/$route'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const RecoveryException(RecoveryError.offline);
    } on http.ClientException {
      throw const RecoveryException(RecoveryError.offline);
    }
    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      // Una respuesta que no es JSON (la función no está): cuenta como error.
    }
    if (res.statusCode == 200) return body;
    throw exceptionFor(res.statusCode, body);
  }

  /// Traduce la respuesta de la función a un error de la app. Un 404 (la
  /// función no está desplegada) o "mail-not-configured" es `notAvailable`.
  static RecoveryException exceptionFor(int status, Map<String, dynamic> body) {
    final code = body['code'];
    final error = switch (code) {
      'mail-not-configured' => RecoveryError.notAvailable,
      'invalid-email' => RecoveryError.invalidEmail,
      'throttled' => RecoveryError.throttled,
      'wrong-code' => RecoveryError.wrongCode,
      'too-many-attempts' => RecoveryError.tooManyAttempts,
      'expired' => RecoveryError.expired,
      'weak-password' => RecoveryError.weakPassword,
      _ => status == 404 || status == 503 ? RecoveryError.notAvailable : RecoveryError.server,
    };
    return RecoveryException(
      error,
      left: (body['left'] as num?)?.toInt(),
      retryAfter: (body['retryAfter'] as num?)?.toInt(),
    );
  }
}

/// Qué tan fuerte es una contraseña, de 0 a 4 (los cuatro segmentos de la
/// barra): 8 o más caracteres, un número, mayúsculas con minúsculas o un
/// signo, y 12 o más caracteres.
int passwordStrength(String password) {
  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'\d').hasMatch(password)) score++;
  final mixed = RegExp('[a-zñáéíóú]').hasMatch(password) && RegExp('[A-ZÑÁÉÍÓÚ]').hasMatch(password);
  if (mixed || RegExp(r'[^A-Za-z0-9ñÑáéíóúÁÉÍÓÚ\s]').hasMatch(password)) score++;
  if (password.length >= 12) score++;
  return score;
}

/// Si la contraseña nueva cumple lo mínimo (lo mismo que exige la función).
bool passwordAcceptable(String password) =>
    password.length >= 8 && RegExp(r'\d').hasMatch(password);

/// "0:42": el tiempo que falta para poder reenviar el código.
String countdownLabel(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
