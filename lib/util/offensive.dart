import 'search_text.dart';

/// Palabras que tapa "Filtrar comentarios ofensivos", ya en minúsculas y sin
/// tildes (como las deja `foldForSearch`). Solo insultos y agravios claros:
/// en una app de música, muchos nombres de bandas y discos llevan palabras
/// fuertes y esos no se tocan (el filtro solo pasa por lo que escribe la
/// gente, no por los títulos).
const Set<String> offensiveWords = {
  // Español.
  'puta', 'putas', 'puto', 'putos', 'hijueputa', 'hijueputas', 'hijodeputa',
  'hijoeputa', 'jueputa', 'gonorrea', 'gonorreas', 'malparido', 'malparida',
  'malparidos', 'malparidas', 'pirobo', 'piroba', 'pirobos', 'marica',
  'maricas', 'maricon', 'maricones', 'mierda', 'mierdas', 'pendejo',
  'pendeja', 'pendejos', 'pendejas', 'cabron', 'cabrona', 'cabrones',
  'culero', 'culera', 'culeros', 'verga', 'vergas', 'zorra', 'zorras',
  'idiota', 'idiotas', 'imbecil', 'imbeciles', 'estupido', 'estupida',
  'estupidos', 'estupidas', 'retrasado', 'retrasada', 'retrasados',
  'mongolico', 'mongolica', 'subnormal', 'subnormales', 'sudaca', 'sudacas',
  'negrata', 'negratas', 'joto', 'jotos', 'chingada', 'chingado', 'pinche',
  'pinches', 'culiao', 'culiado', 'culiada', 'gilipollas', 'malnacido',
  'malnacida', 'careverga', 'carechimba', 'guevon', 'huevon', 'guevona',
  // Inglés.
  'fuck', 'fucks', 'fucked', 'fucking', 'fucker', 'fuckers', 'motherfucker',
  'motherfuckers', 'shit', 'shits', 'shitty', 'bullshit', 'bitch', 'bitches',
  'asshole', 'assholes', 'bastard', 'bastards', 'cunt', 'cunts', 'slut',
  'sluts', 'whore', 'whores', 'faggot', 'faggots', 'fag', 'fags', 'nigger',
  'niggers', 'nigga', 'niggas', 'retard', 'retards', 'retarded', 'kike',
  'kikes', 'spic', 'spics', 'chink', 'chinks', 'tranny', 'trannies',
  'wetback', 'wetbacks', 'dickhead', 'dickheads',
};

final RegExp _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// Si `word` (una sola palabra) es de las que se tapan. No distingue
/// mayúsculas ni tildes.
bool isOffensiveWord(String word) => offensiveWords.contains(foldForSearch(word));

/// Si el texto trae alguna palabra de las que se tapan.
bool hasOffensive(String text) =>
    _word.allMatches(text).any((m) => isOffensiveWord(m[0]!));

/// El texto con las palabras ofensivas tapadas con puntos del mismo largo
/// ("eres un •••••••"). Lo demás (espacios, signos, emojis) queda igual.
String maskOffensive(String text) {
  return text.replaceAllMapped(_word, (m) {
    final word = m[0]!;
    return isOffensiveWord(word) ? '•' * word.runes.length : word;
  });
}
