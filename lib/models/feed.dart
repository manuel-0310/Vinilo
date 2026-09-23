import 'rating.dart';

/// Junta las páginas de actividad de varios trozos de personas seguidas
/// (una consulta `in` por cada 30 uids): quita repetidos por id, ordena de
/// la más reciente a la más antigua y recorta a `limit`.
List<RatingEntry> mergeNewestFirst(
  Iterable<List<RatingEntry>> pages, {
  int limit = 30,
}) {
  final byId = <String, RatingEntry>{};
  for (final page in pages) {
    for (final e in page) {
      final prev = byId[e.id];
      if (prev == null || e.updatedAt.isAfter(prev.updatedAt)) byId[e.id] = e;
    }
  }
  final out = byId.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return out.length > limit ? out.sublist(0, limit) : out;
}
