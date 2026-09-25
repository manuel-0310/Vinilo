import 'rating.dart';

/// Cuánto dura "esta semana" en Popular.
const Duration popularWindow = Duration(days: 7);

/// "Popular esta semana": los discos que alguien calificó en los últimos 7
/// días, de más notas a menos (a igual número, mejor promedio y luego el
/// más reciente). La consulta trae los calificados en la ventana y el orden
/// se hace aquí, así basta el índice de un solo campo de `lastRatedAt`.
List<AlbumStats> popularThisWeek(
  Iterable<AlbumStats> albums,
  DateTime now, {
  int limit = 12,
}) {
  final since = now.subtract(popularWindow);
  final out = albums
      .where((a) => a.count > 0 && (a.lastRatedAt?.isAfter(since) ?? false))
      .toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final byAverage = b.average.compareTo(a.average);
      if (byAverage != 0) return byAverage;
      return b.lastRatedAt!.compareTo(a.lastRatedAt!);
    });
  return out.length > limit ? out.sublist(0, limit) : out;
}
