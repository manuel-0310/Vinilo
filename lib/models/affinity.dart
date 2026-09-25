import 'rating.dart';

/// Afinidad musical entre dos personas: sobre los discos que las dos
/// calificaron, 100 % menos 10 puntos por cada punto de diferencia media
/// (misma nota = 100 %; 10 puntos de diferencia = 0 %). `percent` es null si
/// no tienen discos en común.
({int? percent, int common}) affinityBetween(
  Iterable<RatingEntry> mine,
  Iterable<RatingEntry> theirs,
) {
  final theirScores = {for (final r in theirs) r.albumId: r.score};
  var common = 0;
  var diff = 0;
  for (final m in mine) {
    final t = theirScores[m.albumId];
    if (t == null) continue;
    common++;
    diff += (m.score - t).abs();
  }
  if (common == 0) return (percent: null, common: 0);
  final percent = (100 - diff / common * 10).round().clamp(0, 100);
  return (percent: percent, common: common);
}
