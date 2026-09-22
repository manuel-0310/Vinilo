import '../models/rating.dart';

/// Comentarios de un disco: solo las notas con texto, primero las que tienen
/// más "me gusta" y, en empate, las más recientes. `limit` null devuelve todas.
List<RatingEntry> topComments(Iterable<RatingEntry> entries, {int? limit}) {
  final out = entries.where((e) => e.hasNote).toList()
    ..sort((a, b) {
      final byLikes = b.likes.compareTo(a.likes);
      if (byLikes != 0) return byLikes;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  if (limit != null && out.length > limit) return out.sublist(0, limit);
  return out;
}
