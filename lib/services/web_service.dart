import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/function_url.dart';

/// La función `web` (la de las páginas que se comparten). La app le pide
/// las portadas de la bienvenida, antes de que haya cuenta: por eso no
/// manda token.
class WebService {
  WebService({required String spotifyUrl})
      : _endpoint = siblingFunctionUrl(spotifyUrl, 'web');

  final Uri? _endpoint;
  List<String>? _covers;

  /// Cuántas portadas lleva la rejilla de la bienvenida (4×2).
  static const int welcomeCoverCount = 8;

  /// Las portadas más calificadas (`GET /portadas`). Si la función no
  /// responde, lista vacía: la bienvenida se queda con sus colores planos.
  /// La respuesta buena se guarda para no volver a pedirla.
  Future<List<String>> welcomeCovers() async {
    final cached = _covers;
    if (cached != null) return cached;
    final endpoint = _endpoint;
    if (endpoint == null) return const [];
    try {
      final res = await http
          .get(endpoint.replace(path: '${endpoint.path}/portadas'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final covers = parseCovers(res.body);
      if (covers.isNotEmpty) _covers = covers;
      return covers;
    } catch (_) {
      return const [];
    }
  }

  /// Las URLs https de `{"covers": [...]}`, hasta [welcomeCoverCount].
  static List<String> parseCovers(String body) {
    try {
      final data = jsonDecode(body);
      if (data is! Map || data['covers'] is! List) return const [];
      return (data['covers'] as List)
          .whereType<String>()
          .where((url) => url.startsWith('https://'))
          .take(welcomeCoverCount)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
