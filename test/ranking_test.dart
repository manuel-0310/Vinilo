import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/util/ranking.dart';

RatingEntry entry(
  String id, {
  String note = '',
  int likes = 0,
  int daysAgo = 0,
}) {
  final when = DateTime(2026, 9, 20).subtract(Duration(days: daysAgo));
  return RatingEntry(
    id: id,
    uid: 'u-$id',
    albumId: 'a',
    score: 7,
    note: note,
    createdAt: when,
    updatedAt: when,
    album: const Album(id: 'a', name: 'Disco', artist: 'Alguien'),
    user: RaterInfo(uid: 'u-$id', name: id, colorValue: 0xFFFFFFFF),
    likedBy: List.generate(likes, (i) => 'fan$i'),
  );
}

void main() {
  test('deja fuera las notas sin texto', () {
    final out = topComments([entry('a'), entry('b', note: 'Buenísimo'), entry('c', note: '   ')]);
    expect(out.map((e) => e.id), ['b']);
  });

  test('ordena por likes y, en empate, por fecha reciente', () {
    final out = topComments([
      entry('viejo', note: 'x', likes: 2, daysAgo: 5),
      entry('nuevo', note: 'x', likes: 2, daysAgo: 1),
      entry('top', note: 'x', likes: 9, daysAgo: 30),
      entry('sin', note: 'x', likes: 0, daysAgo: 0),
    ]);
    expect(out.map((e) => e.id), ['top', 'nuevo', 'viejo', 'sin']);
  });

  test('respeta el límite', () {
    final out = topComments(
      [for (var i = 0; i < 6; i++) entry('$i', note: 'x', likes: i)],
      limit: 3,
    );
    expect(out.length, 3);
    expect(out.first.id, '5');
  });

  test('sin límite devuelve todas', () {
    final out = topComments([for (var i = 0; i < 6; i++) entry('$i', note: 'x')]);
    expect(out.length, 6);
  });
}
