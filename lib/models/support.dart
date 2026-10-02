import 'package:cloud_firestore/cloud_firestore.dart';

import 'rating.dart';

/// Un "Reportar el problema" de la pantalla "Se rayó el disco"
/// (`problems/{id}`): quién, el código que vio y qué falló.
class ProblemReport {
  const ProblemReport({
    required this.id,
    required this.uid,
    required this.code,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String code;
  final String detail;
  final DateTime createdAt;

  factory ProblemReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return ProblemReport(
      id: doc.id,
      uid: (d['uid'] ?? '') as String,
      code: (d['code'] ?? '') as String,
      detail: (d['detail'] ?? '') as String,
      createdAt: dateFrom(d['createdAt']),
    );
  }
}

/// Un "Pídenos que lo agreguemos" (`requests/{id}`): lo que se buscó sin
/// encontrar nada.
class AlbumRequest {
  const AlbumRequest({
    required this.id,
    required this.uid,
    required this.query,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String query;
  final DateTime createdAt;

  factory AlbumRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AlbumRequest(
      id: doc.id,
      uid: (d['uid'] ?? '') as String,
      query: (d['query'] ?? '') as String,
      createdAt: dateFrom(d['createdAt']),
    );
  }
}

/// Los pedidos agrupados por lo que se buscó (sin mayúsculas ni espacios
/// de sobra), del más pedido al menos; empatados, el más reciente primero.
List<({String query, int count, DateTime last})> groupRequests(Iterable<AlbumRequest> requests) {
  final groups = <String, ({String query, int count, DateTime last})>{};
  for (final r in requests) {
    final key = r.query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (key.isEmpty) continue;
    final g = groups[key];
    groups[key] = g == null
        ? (query: r.query.trim(), count: 1, last: r.createdAt)
        : (
            query: r.createdAt.isAfter(g.last) ? r.query.trim() : g.query,
            count: g.count + 1,
            last: r.createdAt.isAfter(g.last) ? r.createdAt : g.last,
          );
  }
  return groups.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.last.compareTo(a.last);
    });
}
