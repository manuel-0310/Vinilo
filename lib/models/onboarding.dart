import '../l10n/l10n.dart';
import 'album.dart';
import 'follow.dart';
import 'rating.dart';

/// Los filtros del paso 1 del onboarding ("Elige 3 discos que te
/// encanten"), en el orden en que se ven.
enum TasteGenre {
  popular,
  rock,
  latinPop,
  hipHop,
  electronic,
  pop,
  rnb,
  indie;

  String label(AppLocalizations l) => switch (this) {
        TasteGenre.popular => l.genrePopular,
        TasteGenre.rock => l.genreRock,
        TasteGenre.latinPop => l.genreLatinPop,
        TasteGenre.hipHop => l.genreHipHop,
        TasteGenre.electronic => l.genreElectronic,
        TasteGenre.pop => l.genrePop,
        TasteGenre.rnb => l.genreRnb,
        TasteGenre.indie => l.genreIndie,
      };
}

/// Un disco de la selección de un género: su título y su artista, tal como
/// están en Spotify.
typedef TasteSeed = ({String album, String artist});

/// Cuántos discos enseña cada filtro.
const int tasteGridSize = 12;

/// Mínimo de discos para poder continuar.
const int tastesRequired = 3;

/// Discos conocidos de cada género. Spotify (en modo desarrollo) no deja
/// buscar álbumes por género, así que la selección va escrita aquí y la app
/// busca cada uno por título y artista para traer su portada y su id. En
/// "Populares" solo rellenan si la comunidad todavía ha calificado pocos.
const Map<TasteGenre, List<TasteSeed>> tasteSeeds = {
  TasteGenre.popular: [
    (album: 'OK Computer', artist: 'Radiohead'),
    (album: 'Un Verano Sin Ti', artist: 'Bad Bunny'),
    (album: 'El Mal Querer', artist: 'ROSALÍA'),
    (album: 'Blonde', artist: 'Frank Ocean'),
    (album: 'Bocanada', artist: 'Gustavo Cerati'),
    (album: 'Re', artist: 'Café Tacvba'),
    (album: 'To Pimp A Butterfly', artist: 'Kendrick Lamar'),
    (album: 'Random Access Memories', artist: 'Daft Punk'),
    (album: 'Abbey Road', artist: 'The Beatles'),
    (album: 'Thriller', artist: 'Michael Jackson'),
    (album: 'Currents', artist: 'Tame Impala'),
    (album: 'MOTOMAMI', artist: 'ROSALÍA'),
  ],
  TasteGenre.rock: [
    (album: 'OK Computer', artist: 'Radiohead'),
    (album: 'Abbey Road', artist: 'The Beatles'),
    (album: 'The Dark Side of the Moon', artist: 'Pink Floyd'),
    (album: 'Nevermind', artist: 'Nirvana'),
    (album: 'Canción Animal', artist: 'Soda Stereo'),
    (album: 'Led Zeppelin IV', artist: 'Led Zeppelin'),
    (album: 'Is This It', artist: 'The Strokes'),
    (album: 'AM', artist: 'Arctic Monkeys'),
    (album: 'Rumours', artist: 'Fleetwood Mac'),
    (album: 'Bocanada', artist: 'Gustavo Cerati'),
    (album: 'In Rainbows', artist: 'Radiohead'),
    (album: 'Clics Modernos', artist: 'Charly García'),
  ],
  TasteGenre.latinPop: [
    (album: 'Un Verano Sin Ti', artist: 'Bad Bunny'),
    (album: 'El Mal Querer', artist: 'ROSALÍA'),
    (album: 'YHLQMDLG', artist: 'Bad Bunny'),
    (album: 'MAÑANA SERÁ BONITO', artist: 'KAROL G'),
    (album: 'Dónde Están los Ladrones', artist: 'Shakira'),
    (album: 'Un Día Normal', artist: 'Juanes'),
    (album: 'Hasta la Raíz', artist: 'Natalia Lafourcade'),
    (album: 'Limón y Sal', artist: 'Julieta Venegas'),
    (album: 'Colores', artist: 'J Balvin'),
    (album: 'MOTOMAMI', artist: 'ROSALÍA'),
    (album: 'La Tierra del Olvido', artist: 'Carlos Vives'),
    (album: 'Fórmula, Vol. 2', artist: 'Romeo Santos'),
  ],
  TasteGenre.hipHop: [
    (album: 'To Pimp A Butterfly', artist: 'Kendrick Lamar'),
    (album: 'good kid, m.A.A.d city', artist: 'Kendrick Lamar'),
    (album: 'My Beautiful Dark Twisted Fantasy', artist: 'Kanye West'),
    (album: 'The Miseducation of Lauryn Hill', artist: 'Ms. Lauryn Hill'),
    (album: 'Illmatic', artist: 'Nas'),
    (album: 'The Blueprint', artist: 'JAY-Z'),
    (album: 'IGOR', artist: 'Tyler, The Creator'),
    (album: 'ASTROWORLD', artist: 'Travis Scott'),
    (album: 'Enter The Wu-Tang (36 Chambers)', artist: 'Wu-Tang Clan'),
    (album: 'The College Dropout', artist: 'Kanye West'),
    (album: 'Madvillainy', artist: 'Madvillain'),
    (album: 'Ready to Die', artist: 'The Notorious B.I.G.'),
  ],
  TasteGenre.electronic: [
    (album: 'Random Access Memories', artist: 'Daft Punk'),
    (album: 'Discovery', artist: 'Daft Punk'),
    (album: 'Homogenic', artist: 'Björk'),
    (album: 'Selected Ambient Works 85-92', artist: 'Aphex Twin'),
    (album: 'Music Has The Right To Children', artist: 'Boards of Canada'),
    (album: 'Play', artist: 'Moby'),
    (album: 'Kid A', artist: 'Radiohead'),
    (album: 'Untrue', artist: 'Burial'),
    (album: 'In Colour', artist: 'Jamie xx'),
    (album: 'Mezzanine', artist: 'Massive Attack'),
    (album: 'Dummy', artist: 'Portishead'),
    (album: 'Cross', artist: 'Justice'),
  ],
  TasteGenre.pop: [
    (album: 'Thriller', artist: 'Michael Jackson'),
    (album: '1989', artist: 'Taylor Swift'),
    (album: 'Future Nostalgia', artist: 'Dua Lipa'),
    (album: 'Lemonade', artist: 'Beyoncé'),
    (album: '21', artist: 'Adele'),
    (album: 'Melodrama', artist: 'Lorde'),
    (album: 'Purple Rain', artist: 'Prince'),
    (album: 'Like a Prayer', artist: 'Madonna'),
    (album: 'After Hours', artist: 'The Weeknd'),
    (album: 'SOUR', artist: 'Olivia Rodrigo'),
    (album: 'Born To Die', artist: 'Lana Del Rey'),
    (album: 'WHEN WE ALL FALL ASLEEP, WHERE DO WE GO?', artist: 'Billie Eilish'),
  ],
  TasteGenre.rnb: [
    (album: 'Blonde', artist: 'Frank Ocean'),
    (album: 'channel ORANGE', artist: 'Frank Ocean'),
    (album: 'Ctrl', artist: 'SZA'),
    (album: 'SOS', artist: 'SZA'),
    (album: "What's Going On", artist: 'Marvin Gaye'),
    (album: 'Songs In The Key Of Life', artist: 'Stevie Wonder'),
    (album: 'Back To Black', artist: 'Amy Winehouse'),
    (album: 'Voodoo', artist: "D'Angelo"),
    (album: 'A Seat at the Table', artist: 'Solange'),
    (album: 'The Miseducation of Lauryn Hill', artist: 'Ms. Lauryn Hill'),
    (album: 'Confessions', artist: 'USHER'),
    (album: 'Baduizm', artist: 'Erykah Badu'),
  ],
  TasteGenre.indie: [
    (album: 'Currents', artist: 'Tame Impala'),
    (album: 'Funeral', artist: 'Arcade Fire'),
    (album: 'In the Aeroplane Over the Sea', artist: 'Neutral Milk Hotel'),
    (album: 'Is This It', artist: 'The Strokes'),
    (album: 'For Emma, Forever Ago', artist: 'Bon Iver'),
    (album: 'Punisher', artist: 'Phoebe Bridgers'),
    (album: 'Lonerism', artist: 'Tame Impala'),
    (album: "Whatever People Say I Am, That's What I'm Not", artist: 'Arctic Monkeys'),
    (album: 'Carrie & Lowell', artist: 'Sufjan Stevens'),
    (album: 'Titanic Rising', artist: 'Weyes Blood'),
    (album: 'Turn On The Bright Lights', artist: 'Interpol'),
    (album: 'The Queen Is Dead', artist: 'The Smiths'),
  ],
};

/// La búsqueda de Spotify que trae un disco concreto: con los filtros de
/// campo `album:` y `artist:`, así el primer resultado es ese disco y no una
/// canción o un recopilatorio con el mismo nombre.
String seedQuery(TasteSeed seed) => 'album:${seed.album} artist:${seed.artist}';

/// De una página de resultados, el que mejor corresponde a la semilla: el
/// primero que sea un álbum (no un sencillo) de ese artista; si no, el
/// primer álbum; si no, lo primero que haya.
Album? pickSeedResult(TasteSeed seed, List<Album> results) {
  if (results.isEmpty) return null;
  final artist = seed.artist.toLowerCase();
  bool byArtist(Album a) => a.artist.toLowerCase().contains(artist);
  bool isAlbum(Album a) => a.type == null || a.type == 'album';
  for (final a in results) {
    if (isAlbum(a) && byArtist(a)) return a;
  }
  for (final a in results) {
    if (isAlbum(a)) return a;
  }
  return results.first;
}

/// Junta los discos de un filtro sin repetir (por id) y los recorta a
/// [tasteGridSize]. `first` va primero (los más calificados de la
/// comunidad) y `fill` completa.
List<Album> mergeTasteAlbums(Iterable<Album> first, Iterable<Album?> fill, {int limit = tasteGridSize}) {
  final seen = <String>{};
  final out = <Album>[];
  for (final a in [...first, ...fill.whereType<Album>()]) {
    if (a.id.isEmpty || !seen.add(a.id)) continue;
    out.add(a);
    if (out.length == limit) break;
  }
  return out;
}

/// Elegir o quitar un disco en el paso 1: si ya estaba, sale (y los
/// siguientes suben un puesto); si no, entra al final, hasta `max`.
List<Album> toggleTaste(List<Album> picked, Album album, {required int max}) {
  if (picked.any((a) => a.id == album.id)) {
    return [for (final a in picked) if (a.id != album.id) a];
  }
  if (picked.length >= max) return picked;
  return [...picked, album];
}

/// Por qué se le sugiere seguir a alguien.
enum SuggestionReason {
  /// Le puso 10 a uno de mis discos.
  sameTen,

  /// Calificó (bien) uno de mis discos.
  rated,

  /// No coincide en mis discos, pero la sigue mucha gente.
  popular,
}

/// Alguien a quien seguir en el paso 2: la persona, qué tanto coincide con
/// mis discos (null si es una sugerencia por popularidad) y el motivo.
class PeopleSuggestion {
  const PeopleSuggestion({
    required this.person,
    required this.reason,
    this.percent,
    this.album,
    this.score,
    this.followers = 0,
    this.matched = 0,
  });

  final PersonInfo person;
  final SuggestionReason reason;

  /// Afinidad con mis discos (0–100).
  final int? percent;

  /// El disco del motivo y la nota que le puso.
  final Album? album;
  final int? score;
  final int followers;

  /// En cuántos de mis discos coincide.
  final int matched;

  String reasonText(AppLocalizations l) => switch (reason) {
        SuggestionReason.sameTen => l.suggestSameTen(album?.name ?? ''),
        SuggestionReason.rated => l.suggestRated(album?.name ?? '', score ?? 0),
        SuggestionReason.popular => l.suggestPopular(followers),
      };

  PeopleSuggestion withPerson(PersonInfo person, {int? followers}) => PeopleSuggestion(
        person: person,
        reason: reason,
        percent: percent,
        album: album,
        score: score,
        followers: followers ?? this.followers,
        matched: matched,
      );
}

/// Con qué nota mínima (en promedio, sobre mis discos) alguien cuenta como
/// "gustos parecidos": los discos elegidos son los que me encantan, así que
/// quien les puso menos de 6 no se sugiere.
const int suggestionMinPercent = 60;

/// A quién seguir según los discos que elegí. `ratings` son las notas de
/// otras personas sobre esos discos. La afinidad es su nota media sobre mis
/// discos (un 10 en todos = 100 %); el motivo es su mejor nota. De más
/// afinidad a menos y, empatadas, primero quien coincide en más discos.
List<PeopleSuggestion> suggestByTastes(
  Iterable<RatingEntry> ratings, {
  required Set<String> tasteIds,
  Set<String> exclude = const {},
  int limit = 8,
}) {
  final byUser = <String, List<RatingEntry>>{};
  for (final r in ratings) {
    if (!tasteIds.contains(r.albumId) || exclude.contains(r.uid)) continue;
    byUser.putIfAbsent(r.uid, () => []).add(r);
  }
  final out = <PeopleSuggestion>[];
  for (final entries in byUser.values) {
    final sum = entries.fold<int>(0, (s, r) => s + r.score);
    final percent = (sum / entries.length * 10).round().clamp(0, 100);
    if (percent < suggestionMinPercent) continue;
    final best = [...entries]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : b.updatedAt.compareTo(a.updatedAt);
      });
    final top = best.first;
    out.add(
      PeopleSuggestion(
        person: PersonInfo(
          uid: top.uid,
          name: top.user.name,
          colorValue: top.user.colorValue,
          avatarUrl: top.user.avatarUrl,
        ),
        reason: top.score == 10 ? SuggestionReason.sameTen : SuggestionReason.rated,
        percent: percent,
        album: top.album,
        score: top.score,
        matched: entries.length,
      ),
    );
  }
  out.sort((a, b) {
    final byPercent = b.percent!.compareTo(a.percent!);
    if (byPercent != 0) return byPercent;
    final byMatched = b.matched.compareTo(a.matched);
    return byMatched != 0 ? byMatched : a.person.name.compareTo(b.person.name);
  });
  return out.length > limit ? out.sublist(0, limit) : out;
}

/// Completa las sugerencias con cuentas populares que no estén ya ni se
/// deban excluir, hasta `limit`.
List<PeopleSuggestion> fillWithPopular(
  List<PeopleSuggestion> byTaste,
  Iterable<({PersonInfo person, int followers})> popular, {
  Set<String> exclude = const {},
  int limit = 8,
}) {
  final seen = {for (final s in byTaste) s.person.uid, ...exclude};
  final out = [...byTaste];
  for (final p in popular) {
    if (out.length >= limit) break;
    if (!seen.add(p.person.uid)) continue;
    out.add(
      PeopleSuggestion(
        person: p.person,
        reason: SuggestionReason.popular,
        followers: p.followers,
      ),
    );
  }
  return out;
}
