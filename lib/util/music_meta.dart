import 'format.dart';

/// Nombres de países por su código ISO de dos letras, en español y en
/// inglés. Solo los que más aparecen en una colección de discos; los demás
/// se muestran con su código.
const Map<String, (String es, String en)> _countries = {
  'AR': ('Argentina', 'Argentina'),
  'AU': ('Australia', 'Australia'),
  'AT': ('Austria', 'Austria'),
  'BE': ('Bélgica', 'Belgium'),
  'BO': ('Bolivia', 'Bolivia'),
  'BR': ('Brasil', 'Brazil'),
  'CA': ('Canadá', 'Canada'),
  'CL': ('Chile', 'Chile'),
  'CN': ('China', 'China'),
  'CO': ('Colombia', 'Colombia'),
  'CR': ('Costa Rica', 'Costa Rica'),
  'CU': ('Cuba', 'Cuba'),
  'DK': ('Dinamarca', 'Denmark'),
  'DO': ('Rep. Dominicana', 'Dominican Rep.'),
  'EC': ('Ecuador', 'Ecuador'),
  'SV': ('El Salvador', 'El Salvador'),
  'FI': ('Finlandia', 'Finland'),
  'FR': ('Francia', 'France'),
  'DE': ('Alemania', 'Germany'),
  'GH': ('Ghana', 'Ghana'),
  'GR': ('Grecia', 'Greece'),
  'GT': ('Guatemala', 'Guatemala'),
  'HN': ('Honduras', 'Honduras'),
  'IS': ('Islandia', 'Iceland'),
  'IN': ('India', 'India'),
  'IE': ('Irlanda', 'Ireland'),
  'IL': ('Israel', 'Israel'),
  'IT': ('Italia', 'Italy'),
  'JM': ('Jamaica', 'Jamaica'),
  'JP': ('Japón', 'Japan'),
  'KR': ('Corea del Sur', 'South Korea'),
  'ML': ('Malí', 'Mali'),
  'MX': ('México', 'Mexico'),
  'NL': ('Países Bajos', 'Netherlands'),
  'NZ': ('Nueva Zelanda', 'New Zealand'),
  'NG': ('Nigeria', 'Nigeria'),
  'NO': ('Noruega', 'Norway'),
  'PA': ('Panamá', 'Panama'),
  'PY': ('Paraguay', 'Paraguay'),
  'PE': ('Perú', 'Peru'),
  'PL': ('Polonia', 'Poland'),
  'PT': ('Portugal', 'Portugal'),
  'PR': ('Puerto Rico', 'Puerto Rico'),
  'RU': ('Rusia', 'Russia'),
  'ZA': ('Sudáfrica', 'South Africa'),
  'ES': ('España', 'Spain'),
  'SE': ('Suecia', 'Sweden'),
  'CH': ('Suiza', 'Switzerland'),
  'TR': ('Turquía', 'Turkey'),
  'GB': ('Reino Unido', 'United Kingdom'),
  'US': ('Estados Unidos', 'United States'),
  'UY': ('Uruguay', 'Uruguay'),
  'VE': ('Venezuela', 'Venezuela'),
};

/// "Reino Unido" / "United Kingdom" para "GB"; sin nombre conocido, el
/// código.
String countryName(String code, String localeName) {
  final names = _countries[code.toUpperCase()];
  if (names == null) return code.toUpperCase();
  return localeName.startsWith('en') ? names.$2 : names.$1;
}

/// Los géneros llegan en inglés y en minúsculas ("alternative rock"). En
/// español, los más comunes tienen su nombre; el resto se muestra tal cual,
/// con mayúscula inicial.
const Map<String, String> _genresEs = {
  'alternative rock': 'Rock alternativo',
  'indie rock': 'Rock indie',
  'art rock': 'Art rock',
  'rock': 'Rock',
  'pop rock': 'Pop rock',
  'hard rock': 'Hard rock',
  'progressive rock': 'Rock progresivo',
  'psychedelic rock': 'Rock psicodélico',
  'punk rock': 'Punk rock',
  'post-punk': 'Post-punk',
  'new wave': 'New wave',
  'latin rock': 'Rock latino',
  'rock en español': 'Rock en español',
  'pop': 'Pop',
  'latin pop': 'Pop latino',
  'latin': 'Latina',
  'art pop': 'Art pop',
  'indie pop': 'Pop indie',
  'synth-pop': 'Synth-pop',
  'dream pop': 'Dream pop',
  'electropop': 'Electropop',
  'k-pop': 'K-pop',
  'hip hop': 'Hip hop',
  'rap': 'Rap',
  'trap': 'Trap',
  'latin trap': 'Trap latino',
  'reggaeton': 'Reguetón',
  'electronic': 'Electrónica',
  'house': 'House',
  'techno': 'Techno',
  'ambient': 'Ambient',
  'idm': 'IDM',
  'trip hop': 'Trip hop',
  'downtempo': 'Downtempo',
  'dance': 'Dance',
  'r&b': 'R&B',
  'contemporary r&b': 'R&B contemporáneo',
  'soul': 'Soul',
  'neo soul': 'Neo soul',
  'funk': 'Funk',
  'jazz': 'Jazz',
  'blues': 'Blues',
  'folk': 'Folk',
  'indie folk': 'Folk indie',
  'country': 'Country',
  'metal': 'Metal',
  'heavy metal': 'Heavy metal',
  'classical': 'Clásica',
  'reggae': 'Reggae',
  'salsa': 'Salsa',
  'cumbia': 'Cumbia',
  'bachata': 'Bachata',
  'flamenco': 'Flamenco',
  'tango': 'Tango',
  'bossa nova': 'Bossa nova',
  'singer-songwriter': 'Cantautor',
  'experimental': 'Experimental',
  'shoegaze': 'Shoegaze',
  'grunge': 'Grunge',
};

/// El nombre de un género para mostrar.
String genreLabel(String genre, String localeName) {
  final key = genre.trim().toLowerCase();
  if (!localeName.startsWith('en')) {
    final es = _genresEs[key];
    if (es != null) return es;
  }
  // "idm" o "r&b" van en mayúsculas; lo demás, con inicial mayúscula.
  if (key.length <= 3 || key == 'r&b') return key.toUpperCase();
  return capitalize(key);
}
