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

/// La sección "Actividad" del inicio: si sigo a alguien y lo último que
/// calificaron las personas que sigo.
class FollowingFeed {
  const FollowingFeed({required this.followsAnyone, required this.entries});

  const FollowingFeed.nobody()
      : followsAnyone = false,
        entries = const [];

  final bool followsAnyone;
  final List<RatingEntry> entries;
}

/// Cuánto cuenta como "nueva" una nota de la actividad.
const Duration freshWindow = Duration(hours: 24);

/// "N nuevas" en la actividad: las notas de amigos de las últimas 24 h.
int freshCount(Iterable<RatingEntry> entries, DateTime now) {
  final since = now.subtract(freshWindow);
  return entries.where((e) => e.updatedAt.isAfter(since)).length;
}

/// "Calificado por": las notas de mis amigos sobre un disco, de mayor a menor
/// nota y, a igual nota, la más reciente primero. Sin repetidos.
List<RatingEntry> friendsByScore(Iterable<List<RatingEntry>> pages) {
  final byId = <String, RatingEntry>{
    for (final page in pages)
      for (final e in page) e.id: e,
  };
  return byId.values.toList()
    ..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.updatedAt.compareTo(a.updatedAt);
    });
}
