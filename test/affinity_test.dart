import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/affinity.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/rating.dart';

RatingEntry rating(String uid, String album, int score, {DateTime? at}) {
  final when = at ?? DateTime(2026, 9, 25);
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

  group('discos en común', () {
    test('solo los que calificamos las dos, con las dos notas', () {
      final a = affinityBetween(
        [rating('yo', 'a', 9), rating('yo', 'b', 7), rating('yo', 'solo-mio', 2)],
        [rating('otra', 'b', 5), rating('otra', 'a', 9), rating('otra', 'solo-suyo', 10)],
      );
      expect(a.albums.map((c) => c.album.id), ['a', 'b']);
      expect(a.albums.first.mine, 9);
      expect(a.albums.first.theirs, 9);
      expect(a.albums.last.mine, 7);
      expect(a.albums.last.theirs, 5);
      expect(a.albums.last.difference, 2);
      expect(a.common, a.albums.length);
    });

    test('misma nota primero, luego menos diferencia y, empatados, el más reciente', () {
      final a = affinityBetween(
        [
          rating('yo', 'lejos', 2, at: DateTime(2026, 9, 20)),
          rating('yo', 'cerca-viejo', 8, at: DateTime(2026, 1, 1)),
          rating('yo', 'igual', 7, at: DateTime(2025, 5, 1)),
          rating('yo', 'cerca-nuevo', 6, at: DateTime(2026, 2, 1)),
        ],
        [
          rating('otra', 'cerca-nuevo', 5, at: DateTime(2026, 9, 1)),
          rating('otra', 'lejos', 9, at: DateTime(2026, 9, 20)),
          rating('otra', 'igual', 7, at: DateTime(2025, 5, 1)),
          rating('otra', 'cerca-viejo', 9, at: DateTime(2026, 3, 1)),
        ],
      );
      expect(a.albums.map((c) => c.album.id), ['igual', 'cerca-nuevo', 'cerca-viejo', 'lejos']);
      // La fecha es la más reciente de las dos notas.
      expect(a.albums[1].at, DateTime(2026, 9, 1));
    });

    test('sin repetidos aunque una lista traiga el mismo disco dos veces', () {
      final a = affinityBetween(
        [rating('yo', 'a', 9), rating('yo', 'a', 9)],
        [rating('otra', 'a', 8)],
      );
      expect(a.albums, hasLength(1));
      expect(a.common, 1);
      expect(a.percent, 90);
    });

    test('sin discos en común, la lista vacía', () {
      expect(affinityBetween([rating('yo', 'a', 5)], [rating('otra', 'b', 5)]).albums, isEmpty);
    });
  });
}
