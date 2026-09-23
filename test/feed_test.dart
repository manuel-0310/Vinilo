import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/feed.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/util/chunks.dart';

RatingEntry entry(String id, int minutesAgo) {
  final when = DateTime(2026, 9, 22, 12).subtract(Duration(minutes: minutesAgo));
  return RatingEntry(
    id: id,
    uid: 'u-$id',
    albumId: 'a',
    score: 7,
    note: '',
    createdAt: when,
    updatedAt: when,
    album: const Album(id: 'a', name: 'Disco', artist: 'Alguien'),
    user: RaterInfo(uid: 'u-$id', name: id, colorValue: 0xFFFFFFFF),
  );
}

void main() {
  group('chunked', () {
    test('parte en trozos de 30 como exige la consulta in', () {
      final ids = List.generate(65, (i) => 'u$i');
      final parts = chunked(ids, firestoreInLimit);
      expect(parts.length, 3);
      expect(parts[0].length, 30);
      expect(parts[1].length, 30);
      expect(parts[2].length, 5);
      expect(parts.expand((p) => p).toList(), ids);
    });

    test('con menos de 30 es un solo trozo y con nada no hay trozos', () {
      expect(chunked(['a', 'b'], 30), [['a', 'b']]);
      expect(chunked(<String>[], 30), isEmpty);
    });
  });

  group('mergeNewestFirst', () {
    test('junta varias páginas, quita repetidos y ordena por fecha', () {
      final merged = mergeNewestFirst([
        [entry('a', 10), entry('b', 30)],
        [entry('c', 5), entry('a', 10)],
      ]);
      expect(merged.map((e) => e.id), ['c', 'a', 'b']);
    });

    test('recorta al límite', () {
      final merged = mergeNewestFirst(
        [List.generate(50, (i) => entry('e$i', i))],
        limit: 30,
      );
      expect(merged.length, 30);
      expect(merged.first.id, 'e0');
      expect(merged.last.id, 'e29');
    });

    test('sin páginas no hay actividad', () {
      expect(mergeNewestFirst(const []), isEmpty);
    });
  });
}
