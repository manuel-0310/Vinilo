import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import '../services/account_service.dart';
import '../services/lists_repo.dart';
import '../services/spotify_api.dart';
import 'auth_errors.dart';

/// Texto para mostrar cualquier error en el idioma de la app: los conocidos
/// (Spotify, cuenta, listas, Firebase) con su mensaje propio; el resto con
/// uno genérico.
String describeError(Object? error, AppLocalizations l) {
  if (error is SpotifyApiException) {
    return switch (error.kind) {
      SpotifyError.notConfigured => l.spotifyNotConfigured,
      SpotifyError.timeout => l.spotifyTimeout,
      SpotifyError.offline => l.errorOffline,
      SpotifyError.server => l.spotifyServerError('${error.status ?? ''}'),
      SpotifyError.unexpected => l.spotifyUnexpected,
    };
  }
  if (error is AccountDeletionException) return error.message(l);
  if (error is ListGoneException) return l.listGone;
  if (error == null) return l.errorGeneric;
  return friendlyError(error, l);
}

/// Se cortó la conexión (o no hay): lo que se intentaba vale la pena
/// guardarlo para después ("Sin conexión", la cola de notas). Un error del
/// servidor o de permisos no cuenta.
bool isOfflineError(Object? error) {
  if (error == null) return false;
  if (error is SpotifyApiException) {
    return error.kind == SpotifyError.offline || error.kind == SpotifyError.timeout;
  }
  if (error is TimeoutException || error is http.ClientException) return true;
  if (error is FirebaseException) {
    return const {'unavailable', 'deadline-exceeded', 'network-request-failed'}
        .contains(error.code);
  }
  // `SocketException` es de dart:io, que no existe en la web.
  return error.runtimeType.toString() == 'SocketException';
}

/// Algo falló del lado del servidor (no es la conexión): la pantalla "Se
/// rayó el disco".
bool isServerError(Object? error) {
  if (error is SpotifyApiException) {
    final status = error.status ?? 0;
    return error.kind == SpotifyError.server && status >= 500;
  }
  if (error is FirebaseException) {
    return const {'internal', 'data-loss'}.contains(error.code);
  }
  return false;
}

/// El estado HTTP que se muestra en grande ("500"): el que mandó el
/// servidor si lo hay; si no, 500.
int serverStatusOf(Object? error) {
  if (error is SpotifyApiException && (error.status ?? 0) >= 500) return error.status!;
  return 500;
}

/// Código corto para que la persona lo pueda citar al reportar
/// ("VN-500-7F2A"): el estado y cuatro cifras hexadecimales al azar.
String errorCode(Object? error, [math.Random? random]) {
  final hex = (random ?? math.Random()).nextInt(0x10000).toRadixString(16).toUpperCase();
  return 'VN-${serverStatusOf(error)}-${hex.padLeft(4, '0')}';
}
