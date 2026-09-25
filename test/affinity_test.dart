import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/affinity.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/rating.dart';

RatingEntry rating(String uid, String album, int score) {
  final when = DateTime(2026, 9, 25);
  return RatingEntry(
    id: '${uid}_$album',
    uid: uid,
    albumId: album,
    score: score,
    note: '',
    createdAt: when,
    updatedAt: when,
    album: Album(id: album, name: album, artist: 'x'),
    user: RaterInfo(uid: uid, name: uid, colorValue: 0xFFFFFFFF),
  );
}

void main() {
  test('misma nota en todo lo común: 100 %', () {
    final a = affinityBetween(
      [rating('yo', 'a', 9), rating('yo', 'b', 7), rating('yo', 'solo-mio', 2)],
      [rating('otra', 'a', 9), rating('otra', 'b', 7), rating('otra', 'solo-suyo', 10)],
    );
    expect(a.percent, 100);
    expect(a.common, 2);
  });

  test('10 puntos menos por cada punto de diferencia media', () {
    final a = affinityBetween(
      [rating('yo', 'a', 10), rating('yo', 'b', 6)],
      [rating('otra', 'a', 9), rating('otra', 'b', 6)],
    );
    // Diferencia media 0,5 → 95 %.
    expect(a.percent, 95);
  });

  test('sin discos en común no hay afinidad, y nunca baja de 0', () {
    expect(affinityBetween([rating('yo', 'a', 5)], [rating('otra', 'b', 5)]).percent, isNull);
    expect(affinityBetween([rating('yo', 'a', 1)], [rating('otra', 'a', 10)]).percent, 10);
  });
}
