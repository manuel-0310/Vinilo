import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/album.dart';
import '../models/artist.dart';

class SpotifyApiException implements Exception {
  SpotifyApiException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => message;
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
  final Map<String, List<Artist>> _artists = {};
  final Map<String, Artist> _artistDetails = {};

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<AlbumPage> search(String query, {int offset = 0}) =>
      _page('/search', {'q': query, 'offset': '$offset'});

  Future<AlbumPage> artistAlbums(String artistId, {int offset = 0}) =>
      _page('/artist/$artistId/albums', {'offset': '$offset'});

  Future<List<Artist>> searchArtists(String query) async {
    final key = query.trim().toLowerCase();
    final cached = _artists[key];
    if (cached != null) return cached;
    final body = await _get('/artists/search', {'q': query});
    final items = ((body['items'] as List?) ?? const [])
        .map((j) => Artist.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    _artists[key] = items;
    return items;
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
      throw SpotifyApiException(
        'Falta la URL de la función de Spotify. Corre la app con '
        '--dart-define=SPOTIFY_FN_URL=…',
      );
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
      throw SpotifyApiException('Spotify tardó demasiado en responder.');
    } on http.ClientException catch (e) {
      throw SpotifyApiException('Sin conexión: ${e.message}');
    }
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (res.statusCode != 200) {
      final message = body is Map && body['error'] is String
          ? body['error'] as String
          : 'Error ${res.statusCode}';
      throw SpotifyApiException(message, status: res.statusCode);
    }
    if (body is! Map<String, dynamic>) {
      throw SpotifyApiException('Respuesta inesperada de Spotify.');
    }
    return body;
  }
}
