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

/// Las pestañas de la pantalla de afinidad: todos los discos en común, los
/// que coinciden (a 1 punto o menos) y en los que discrepamos (a 2 o más).
enum AffinityFilter { all, match, differ }

/// Si un disco entra en la pestaña `filter`.
bool affinityIn(CommonAlbum album, AffinityFilter filter) => switch (filter) {
      AffinityFilter.all => true,
      AffinityFilter.match => album.difference <= 1,
      AffinityFilter.differ => album.difference >= 2,
    };

/// El orden por defecto de cada pestaña: en "Discrepan", los más distintos
/// primero; en las otras, los más parecidos.
bool affinityDefaultDesc(AffinityFilter filter) => filter == AffinityFilter.differ;

/// Los discos de la pestaña, ordenados por diferencia (creciente, o
/// decreciente con `mostDifferentFirst`) y, a igual diferencia, el más
/// reciente primero.
List<CommonAlbum> affinityView(
  Iterable<CommonAlbum> albums,
  AffinityFilter filter, {
  required bool mostDifferentFirst,
}) {
  final out = [for (final a in albums) if (affinityIn(a, filter)) a];
  out.sort((a, b) {
    final byDiff = mostDifferentFirst
        ? b.difference.compareTo(a.difference)
        : a.difference.compareTo(b.difference);
    return byDiff != 0 ? byDiff : b.at.compareTo(a.at);
  });
  return out;
}
