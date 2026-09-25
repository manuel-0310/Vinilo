import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/feed.dart';
import 'package:no_retiene/models/popular.dart';
import 'package:no_retiene/models/rating.dart';

final now = DateTime(2026, 9, 25, 12);

AlbumStats stats(String id, {required int count, double average = 8, required int daysAgo}) {
  return AlbumStats(
    album: Album(id: id, name: id, artist: 'Alguien'),
    count: count,
    sum: average * count,
    hist: const {},
    lastRatedAt: now.subtract(Duration(days: daysAgo, minutes: 1)),
  );
}

RatingEntry entry(String id, {required int hoursAgo}) {
  final when = now.subtract(Duration(hours: hoursAgo));
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
  group('popularThisWeek', () {
    test('solo los calificados en los últimos 7 días', () {
      final out = popularThisWeek([
        stats('hoy', count: 1, daysAgo: 0),
        stats('seis', count: 2, daysAgo: 6),
        stats('ocho', count: 50, daysAgo: 8),
      ], now);
      expect(out.map((a) => a.album.id), ['seis', 'hoy']);
    });

    test('de más notas a menos; a igual número, mejor promedio', () {
      final out = popularThisWeek([
        stats('pocas', count: 2, daysAgo: 1),
        stats('muchas', count: 9, daysAgo: 3),
        stats('mismas-mejor', count: 2, average: 9.5, daysAgo: 2),
      ], now);
      expect(out.map((a) => a.album.id), ['muchas', 'mismas-mejor', 'pocas']);
    });

    test('sin notas o sin fecha no cuentan, y respeta el límite', () {
      final out = popularThisWeek([
        stats('vacio', count: 0, daysAgo: 1),
        AlbumStats(album: const Album(id: 'sin-fecha', name: 'x', artist: 'y'), count: 3, sum: 21, hist: const {}),
        for (var i = 0; i < 20; i++) stats('d$i', count: i + 1, daysAgo: 1),
      ], now, limit: 5);
      expect(out, hasLength(5));
      expect(out.first.album.id, 'd19');
      expect(out.any((a) => a.album.id == 'vacio' || a.album.id == 'sin-fecha'), isFalse);
    });
  });

  test('freshCount: las notas de amigos de las últimas 24 h', () {
    expect(
      freshCount([
        entry('a', hoursAgo: 1),
        entry('b', hoursAgo: 23),
        entry('c', hoursAgo: 25),
        entry('d', hoursAgo: 72),
      ], now),
      2,
    );
    expect(freshCount(const [], now), 0);
  });
}
