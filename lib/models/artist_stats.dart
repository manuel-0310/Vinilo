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
