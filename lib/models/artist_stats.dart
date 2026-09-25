import 'album.dart';
import 'rating.dart';

/// Calificación de un artista en Vinilo: el promedio de todas las notas que
/// la gente puso a sus discos, ponderado por el número de notas (un disco
/// con 40 notas pesa 40 veces más que uno con 1). Spotify no da notas.
class ArtistSummary {
  const ArtistSummary({
    required this.count,
    required this.sum,
    required this.hist,
    required this.ratedAlbums,
  });

  /// Notas en total, sumando todos los discos.
  final int count;
  final num sum;

  /// Histograma "1".."10" agregado.
  final Map<int, int> hist;

  /// Discos con al menos una nota.
  final int ratedAlbums;

  double? get average => count == 0 ? null : sum / count;

  static ArtistSummary from(Iterable<AlbumStats> albums) {
    var count = 0;
    num sum = 0;
    var rated = 0;
    final hist = {for (var i = 1; i <= 10; i++) i: 0};
    for (final a in albums) {
      if (a.count <= 0) continue;
      count += a.count;
      sum += a.sum;
      rated += 1;
      for (final e in a.hist.entries) {
        hist[e.key] = (hist[e.key] ?? 0) + e.value;
      }
    }
    return ArtistSummary(count: count, sum: sum, hist: hist, ratedAlbums: rated);
  }
}

/// La discografía en el orden elegido: tal como llega de Spotify (los más
/// recientes primero) o, con `bestFirst`, de mejor a peor promedio en
/// Vinilo (a igual promedio, el que tiene más notas) y los discos sin
/// notas al final, en su orden de siempre.
List<Album> sortDiscography(
  List<Album> albums,
  Map<String, AlbumStats> stats, {
  required bool bestFirst,
}) {
  if (!bestFirst) return albums;
  final rated = <Album>[];
  final unrated = <Album>[];
  for (final a in albums) {
    ((stats[a.id]?.count ?? 0) > 0 ? rated : unrated).add(a);
  }
  final position = {for (final (i, a) in albums.indexed) a.id: i};
  rated.sort((a, b) {
    final sa = stats[a.id]!;
    final sb = stats[b.id]!;
    final byAverage = sb.average.compareTo(sa.average);
    if (byAverage != 0) return byAverage;
    final byCount = sb.count.compareTo(sa.count);
    if (byCount != 0) return byCount;
    return position[a.id]!.compareTo(position[b.id]!);
  });
  return [...rated, ...unrated];
}
