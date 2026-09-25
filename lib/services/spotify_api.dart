import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/album.dart';
import '../models/artist.dart';

/// Qué falló al hablar con la función de Spotify. El texto para la persona
/// lo pone `describeError` (util/errors.dart) en su idioma.
enum SpotifyError { notConfigured, timeout, offline, server, unexpected }

class SpotifyApiException implements Exception {
  SpotifyApiException(this.kind, {this.status, this.detail});

  final SpotifyError kind;
  final int? status;

  /// Mensaje técnico (del servidor o del cliente HTTP), para depurar.
  final String? detail;

  @override
  String toString() => 'SpotifyApiException($kind, $status, $detail)';
}

/// Cliente de la Cloud Function que hace de proxy de Spotify.
/// La URL llega por `--dart-define=SPOTIFY_FN_URL=…`.
class SpotifyApi {
  SpotifyApi({required String baseUrl, required this.idToken})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  static const String configuredUrl = String.fromEnvironment('SPOTIFY_FN_URL');

  final String baseUrl;
  final Future<String?> Function() idToken;
  final http.Client _client = http.Client();
  final Map<String, AlbumDetail> _albums = {};
  final Map<String, AlbumPage> _pages = {};
  final Map<String, ArtistPage> _artists = {};
  final Map<String, Artist> _artistDetails = {};

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<AlbumPage> search(String query, {int offset = 0}) =>
      _page('/search', {'q': query, 'offset': '$offset'});

  Future<AlbumPage> artistAlbums(String artistId, {int offset = 0}) =>
      _page('/artist/$artistId/albums', {'offset': '$offset'});

  /// La primera página de artistas que coinciden (la fila "Artistas" del
  /// buscador y el selector de favoritos).
  Future<List<Artist>> searchArtists(String query) async =>
      (await searchArtistsPage(query)).items;

  /// Una página de artistas: "Ver todos" sigue pidiendo con `offset`.
  Future<ArtistPage> searchArtistsPage(String query, {int offset = 0}) async {
    final key = '${query.trim().toLowerCase()}@$offset';
    final cached = _artists[key];
    if (cached != null) return cached;
    final page = ArtistPage.fromJson(
      await _get('/artists/search', {'q': query, 'offset': '$offset'}),
    );
    _artists[key] = page;
    return page;
  }

  /// Ficha del artista (nombre, foto, géneros).
  Future<Artist> artist(String id) async {
    final cached = _artistDetails[id];
    if (cached != null) return cached;
    final artist = Artist.fromJson(await _get('/artist/$id'));
    _artistDetails[id] = artist;
    return artist;
  }

  AlbumDetail? cachedAlbum(String id) => _albums[id];

  Future<AlbumDetail> album(String id) async {
    final cached = _albums[id];
    if (cached != null) return cached;
    final detail = AlbumDetail.fromJson(await _get('/album/$id'));
    _albums[id] = detail;
    return detail;
  }

  Future<AlbumPage> _page(String path, Map<String, String> query) async {
    final key = '$path?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final cached = _pages[key];
    if (cached != null) return cached;
    final page = AlbumPage.fromJson(await _get(path, query));
    _pages[key] = page;
    return page;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    if (!isConfigured) {
      throw SpotifyApiException(SpotifyError.notConfigured);
    }
    final token = await idToken();
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: query.isEmpty ? null : query);
    http.Response res;
    try {
      res = await _client.get(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw SpotifyApiException(SpotifyError.timeout);
    } on http.ClientException catch (e) {
      throw SpotifyApiException(SpotifyError.offline, detail: e.message);
    }
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (res.statusCode != 200) {
      final detail = body is Map && body['error'] is String ? body['error'] as String : null;
      throw SpotifyApiException(SpotifyError.server, status: res.statusCode, detail: detail);
    }
    if (body is! Map<String, dynamic>) {
      throw SpotifyApiException(SpotifyError.unexpected);
    }
    return body;
  }
}
