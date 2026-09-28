import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/same_score.dart';

RatingEntry rating(String album, int score, DateTime at) => RatingEntry(
      id: 'yo_$album',
      uid: 'yo',
      albumId: album,
      score: score,
      note: '',
      createdAt: at,
      updatedAt: at,
      album: Album(id: album, name: album, artist: 'x'),
      user: const RaterInfo(uid: 'yo', name: 'yo', colorValue: 0xFFFFFFFF),
    );

void main() {
  final mine = [
    rating('a', 7, DateTime(2026, 3, 1)),
    rating('b', 9, DateTime(2026, 8, 1)),
    rating('c', 7, DateTime(2026, 9, 1)),
    rating('actual', 7, DateTime(2026, 9, 20)),
    rating('d', 7, DateTime(2026, 5, 1)),
  ];

  test('solo los de la misma nota, del más reciente al más antiguo', () {
    expect(ratedWith(mine, 7).map((r) => r.albumId), ['actual', 'c', 'd', 'a']);
  });

  test('sin el disco que se está calificando', () {
    expect(ratedWith(mine, 7, except: 'actual').map((r) => r.albumId), ['c', 'd', 'a']);
  });

  test('ninguno con esa nota', () {
    expect(ratedWith(mine, 3), isEmpty);
  });

  test('no repite un disco', () {
    final dup = [...mine, rating('c', 7, DateTime(2026, 1, 1))];
    expect(ratedWith(dup, 7).where((r) => r.albumId == 'c'), hasLength(1));
  });
}
