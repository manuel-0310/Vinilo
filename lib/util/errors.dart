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
