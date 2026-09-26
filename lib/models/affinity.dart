import 'album.dart';
import 'rating.dart';

/// Un disco que calificamos las dos personas: mi nota y la suya.
class CommonAlbum {
  const CommonAlbum({
    required this.album,
    required this.mine,
    required this.theirs,
    required this.at,
  });

  final Album album;
  final int mine;
  final int theirs;

  /// La más reciente de las dos notas (desempata el orden).
  final DateTime at;

  /// Cuántos puntos nos separan en este disco.
  int get difference => (mine - theirs).abs();
}

/// Afinidad musical entre dos personas: sobre los discos que las dos
/// calificaron, 100 % menos 10 puntos por cada punto de diferencia media
/// (misma nota = 100 %; 10 puntos de diferencia = 0 %). `percent` es null si
/// no tienen discos en común.
///
/// `albums` son esos discos, sin repetir: primero los de la misma nota,
/// después por diferencia creciente y, a igual diferencia, el más reciente.
/// Los usan las miniaturas del perfil ajeno (y la historia "amigo").
({int? percent, int common, List<CommonAlbum> albums}) affinityBetween(
  Iterable<RatingEntry> mine,
  Iterable<RatingEntry> theirs,
) {
  final theirByAlbum = {for (final r in theirs) r.albumId: r};
  final seen = <String>{};
  final albums = <CommonAlbum>[];
  var diff = 0;
  for (final m in mine) {
    final t = theirByAlbum[m.albumId];
    if (t == null || !seen.add(m.albumId)) continue;
    final common = CommonAlbum(
      album: m.album,
      mine: m.score,
      theirs: t.score,
      at: m.updatedAt.isAfter(t.updatedAt) ? m.updatedAt : t.updatedAt,
    );
    albums.add(common);
    diff += common.difference;
  }
  if (albums.isEmpty) return (percent: null, common: 0, albums: const []);
  albums.sort((a, b) {
    final byDiff = a.difference.compareTo(b.difference);
    return byDiff != 0 ? byDiff : b.at.compareTo(a.at);
  });
  final percent = (100 - diff / albums.length * 10).round().clamp(0, 100);
  return (percent: percent, common: albums.length, albums: albums);
}
