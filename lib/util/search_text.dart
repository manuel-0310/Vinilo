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
