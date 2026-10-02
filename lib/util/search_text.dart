import '../models/album.dart';

const Map<String, String> _folds = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
};

/// Texto listo para comparar en una búsqueda: minúsculas, sin tildes ni
/// diéresis, la ñ como n y los espacios de sobra recortados. "Café Tacvba"
/// y "cafe tacvba" dan lo mismo.
String foldForSearch(String text) {
  final lower = text.toLowerCase().trim();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    out.write(_folds[ch] ?? ch);
  }
  // Las tildes que llegan como carácter aparte (letra + acento combinado)
  // también se quitan.
  return out
      .toString()
      .replaceAll(RegExp('[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Si el disco coincide con lo que se escribió, por su nombre o por el de
/// su artista. Sin texto, todo coincide.
bool albumMatches(Album album, String query) {
  final q = foldForSearch(query);
  if (q.isEmpty) return true;
  return foldForSearch(album.name).contains(q) ||
      foldForSearch(album.artist).contains(q);
}

/// Otras búsquedas para "¿Quisiste decir?" cuando una no encontró nada, de
/// la más parecida a la menos: sin letras repetidas de más ("ceratti" →
/// "cerati"), y cada palabra larga sola, de la más larga a la más corta
/// (así "ceratti bocanda" prueba "cerati bocanda", "cerati" y "bocanda").
/// Nunca repite la búsqueda original y da como mucho `max`.
List<String> didYouMeanQueries(String query, {int max = 3}) {
  final original = foldForSearch(query);
  if (original.isEmpty || original.startsWith('@')) return const [];
  String squeeze(String s) => s.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  // De la más larga a la más corta; empatadas, en el orden en que se
  // escribieron.
  final all = original.split(' ');
  final words = all.where((w) => w.length >= 4).toList()
    ..sort((a, b) {
      final byLength = b.length.compareTo(a.length);
      return byLength != 0 ? byLength : all.indexOf(a).compareTo(all.indexOf(b));
    });
  final out = <String>[];
  void add(String candidate) {
    final c = candidate.trim();
    if (c.length < 3 || c == original || out.contains(c)) return;
    out.add(c);
  }

  add(squeeze(original));
  if (words.length > 1) {
    for (final w in words) {
      add(squeeze(w));
    }
  }
  return out.take(max).toList();
}
