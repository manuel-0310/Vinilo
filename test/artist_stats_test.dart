import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/artist_stats.dart';
import 'package:no_retiene/models/rating.dart';

AlbumStats stats(String id, {required int count, required num sum, Map<int, int>? hist}) =>
    AlbumStats(
      album: Album(id: id, name: id, artist: 'X'),
      count: count,
      sum: sum,
      hist: hist ?? {},
    );

void main() {
  test('sin notas no hay promedio', () {
    final s = ArtistSummary.from([stats('a', count: 0, sum: 0)]);
    expect(s.average, isNull);
    expect(s.count, 0);
    expect(s.ratedAlbums, 0);
  });

  test('pondera por número de notas, no promedia los promedios', () {
    // Disco A: 40 notas de 9 (promedio 9). Disco B: 1 nota de 3 (promedio 3).
    // Promedio de promedios sería 6; el ponderado es (360 + 3) / 41 ≈ 8,85.
    final s = ArtistSummary.from([
      stats('a', count: 40, sum: 360),
      stats('b', count: 1, sum: 3),
    ]);
    expect(s.count, 41);
    expect(s.ratedAlbums, 2);
    expect(s.average, closeTo(363 / 41, 1e-9));
  });

  test('agrega los histogramas e ignora discos sin notas', () {
    final s = ArtistSummary.from([
      stats('a', count: 2, sum: 15, hist: {7: 1, 8: 1}),
      stats('b', count: 1, sum: 8, hist: {8: 1}),
      stats('c', count: 0, sum: 0, hist: {5: 3}),
    ]);
    expect(s.hist[8], 2);
    expect(s.hist[7], 1);
    expect(s.hist[5], 0);
    expect(s.ratedAlbums, 2);
  });
}
