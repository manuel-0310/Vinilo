import 'rating.dart';

/// Mis notas con el mismo valor que `score`, sin el disco que estoy
/// calificando (`except`) y sin repetir disco, de la más reciente a la más
/// antigua. Las usa "Otros discos calificados con N" de la hoja de Calificar.
List<RatingEntry> ratedWith(
  Iterable<RatingEntry> mine,
  int score, {
  String? except,
}) {
  final seen = <String>{};
  final out = [
    for (final r in mine)
      if (r.score == score && r.albumId != except && seen.add(r.albumId)) r,
  ];
  out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return out;
}
