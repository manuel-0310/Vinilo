// Perfiles de prueba para ver Vinilo con gente: `msg seed-fake-people` los
// crea (o completa) con los mismos repositorios de la app y
// `msg delete-fake-people` los borra con la función `account`. Todos usan
// correos @vinilo.test y la misma contraseña. Los discos se buscan en
// Spotify con `query` y se toma el primer resultado.

/// Contraseña de todas las cuentas de prueba.
const String fakePassword = 'ViniloPrueba2026';

/// La cuenta de Manuel (@manuel, la que creó en la app nueva): tres perfiles
/// la siguen y le dan "me gusta" a algunas de sus notas, nada más.
const String manuelUid = '9G1HedDHpPQz3Jk4XPFrqrqesNF3';

class FakeRating {
  const FakeRating(this.query, this.score, [this.note]);

  /// Búsqueda en Spotify ("Disco Artista").
  final String query;
  final int score;

  /// Comentario corto (≤180), o null.
  final String? note;
}

class FakePerson {
  const FakePerson({
    required this.email,
    required this.name,
    required this.username,
    required this.colorValue,
    required this.ratings,
    required this.favorites,
    required this.favoriteArtists,
    required this.rankingFrom,
    required this.rankingName,
    required this.rankingSeed,
    required this.albumListName,
    required this.albumList,
    this.followsManuel = false,
  });

  final String email;
  final String name;
  final String username;
  final int colorValue;
  final List<FakeRating> ratings;

  /// `query` de tres de sus notas.
  final List<String> favorites;

  /// Nombres de artistas para buscar.
  final List<String> favoriteArtists;

  /// `query` de una de sus notas: sus canciones forman el ranking.
  final String rankingFrom;
  final String rankingName;

  /// Semilla para ordenar el ranking siempre igual.
  final int rankingSeed;
  final String albumListName;

  /// `query` de varias de sus notas: forman la lista de discos.
  final List<String> albumList;
  final bool followsManuel;
}

const List<FakePerson> fakePeople = [
  FakePerson(
    email: 'valentina.rios@vinilo.test',
    name: 'Valentina Ríos',
    username: 'vale.rios',
    colorValue: 0xFFB08CF0,
    followsManuel: true,
    ratings: [
      FakeRating('OK Computer Radiohead', 10, 'Cada vez que lo pongo encuentro algo nuevo. Perfecto de principio a fin.'),
      FakeRating('Kid A Radiohead', 9, 'Frío por fuera, pero te abraza cuando menos lo esperas.'),
      FakeRating('Punisher Phoebe Bridgers', 9, 'Para escuchar de noche con audífonos. "I Know The End" me deja en el piso.'),
      FakeRating('Be the Cowboy Mitski', 8),
      FakeRating('Blonde Frank Ocean', 10, 'No hay un disco más íntimo. "Self Control" es otra cosa.'),
      FakeRating('Carrie & Lowell Sufjan Stevens', 9, 'Duele bonito.'),
      FakeRating('In Rainbows Radiohead', 9),
      FakeRating('Titanic Rising Weyes Blood', 8, 'Suena a película de los setenta.'),
      FakeRating('Ants From Up There Black Country, New Road', 8),
      FakeRating('Stranger in the Alps Phoebe Bridgers', 7),
      FakeRating('Laurel Hell Mitski', 6, 'Está bien, pero esperaba más después de Be the Cowboy.'),
      FakeRating('Blue Joni Mitchell', 10),
    ],
    favorites: ['OK Computer Radiohead', 'Blonde Frank Ocean', 'Blue Joni Mitchell'],
    favoriteArtists: ['Radiohead', 'Phoebe Bridgers', 'Mitski'],
    rankingFrom: 'In Rainbows Radiohead',
    rankingName: 'In Rainbows, de mejor a peor',
    rankingSeed: 11,
    albumListName: 'Discos para llorar tranquila',
    albumList: [
      'Punisher Phoebe Bridgers',
      'Carrie & Lowell Sufjan Stevens',
      'Blue Joni Mitchell',
      'Titanic Rising Weyes Blood',
    ],
  ),
  FakePerson(
    email: 'santiago.mejia@vinilo.test',
    name: 'Santiago Mejía',
    username: 'santimejia',
    colorValue: 0xFFD26A5C,
    followsManuel: true,
    ratings: [
      FakeRating('Canción Animal Soda Stereo', 10, 'El mejor disco de rock en español. No se discute.'),
      FakeRating('Re Café Tacvba', 10, 'Un disco en el que cabe todo México.'),
      FakeRating('Dynamo Soda Stereo', 9, 'Ruido, texturas y Cerati en su mejor momento.'),
      FakeRating('Bocanada Gustavo Cerati', 9),
      FakeRating('El Madrileño C. Tangana', 8, 'No pensé que me iba a gustar tanto.'),
      FakeRating('Nada Personal Soda Stereo', 7),
      FakeRating('Hasta la Raíz Natalia Lafourcade', 8, 'Me reconcilió con el pop en español.'),
      FakeRating('Reptilectric Zoé', 7),
      FakeRating('El Circo Maldita Vecindad', 9, 'Clásico. "Pachuco" nunca falla.'),
      FakeRating('Sueño Stereo Soda Stereo', 9),
      FakeRating('Fuerza Natural Gustavo Cerati', 7),
    ],
    favorites: ['Canción Animal Soda Stereo', 'Re Café Tacvba', 'Bocanada Gustavo Cerati'],
    favoriteArtists: ['Soda Stereo', 'Café Tacvba', 'Gustavo Cerati'],
    rankingFrom: 'Canción Animal Soda Stereo',
    rankingName: 'Canción Animal, canción por canción',
    rankingSeed: 23,
    albumListName: 'Rock en español esencial',
    albumList: [
      'Canción Animal Soda Stereo',
      'Re Café Tacvba',
      'El Circo Maldita Vecindad',
      'Bocanada Gustavo Cerati',
      'Dynamo Soda Stereo',
    ],
  ),
  FakePerson(
    email: 'camila.duarte@vinilo.test',
    name: 'Camila Duarte',
    username: 'camiduarte',
    colorValue: 0xFFE07BB0,
    followsManuel: true,
    ratings: [
      FakeRating('Motomami Rosalía', 9, 'Arriesgado y divertido. Hay que escucharlo entero.'),
      FakeRating('El Mal Querer Rosalía', 10, 'Una obra conceptual de verdad.'),
      FakeRating('Future Nostalgia Dua Lipa', 8, 'Disco para bailar en la cocina.'),
      FakeRating('1989 Taylor Swift', 8),
      FakeRating('folklore Taylor Swift', 9, 'Taylor en modo cabaña y le queda perfecto.'),
      FakeRating('Melodrama Lorde', 10, 'Lo escuché mil veces en 2017 y sigue igual de bueno.'),
      FakeRating('SOUR Olivia Rodrigo', 7),
      FakeRating('Emotion Carly Rae Jepsen', 9, 'El secreto mejor guardado del pop.'),
      FakeRating('Renaissance Beyoncé', 9),
      FakeRating('Brat Charli xcx', 8, 'Verde y ruidoso, como debe ser.'),
      FakeRating('Midnights Taylor Swift', 6, 'Tiene momentos, pero se me hace largo.'),
      FakeRating('Un Verano Sin Ti Bad Bunny', 8),
    ],
    favorites: ['El Mal Querer Rosalía', 'Melodrama Lorde', 'folklore Taylor Swift'],
    favoriteArtists: ['Rosalía', 'Taylor Swift', 'Lorde'],
    rankingFrom: 'Melodrama Lorde',
    rankingName: 'Melodrama, mi ranking',
    rankingSeed: 5,
    albumListName: 'Pop perfecto',
    albumList: [
      'Emotion Carly Rae Jepsen',
      'Future Nostalgia Dua Lipa',
      'Melodrama Lorde',
      '1989 Taylor Swift',
      'Renaissance Beyoncé',
    ],
  ),
  FakePerson(
    email: 'andres.herrera@vinilo.test',
    name: 'Andrés Herrera',
    username: 'andresherrera',
    colorValue: 0xFF4FC3B0,
    ratings: [
      FakeRating('Kind of Blue Miles Davis', 10, 'El disco que le pongo a quien dice que no le gusta el jazz.'),
      FakeRating('A Love Supreme John Coltrane', 10),
      FakeRating("Mama's Gun Erykah Badu", 9, 'Groove de principio a fin.'),
      FakeRating("Voodoo D'Angelo", 10, 'Nadie ha sonado así ni antes ni después.'),
      FakeRating('Blue Train John Coltrane', 8),
      FakeRating('Mingus Ah Um Charles Mingus', 9),
      FakeRating('Black Radio Robert Glasper', 7),
      FakeRating('The Epic Kamasi Washington', 8, 'Casi tres horas que se pasan volando.'),
      FakeRating("What's Going On Marvin Gaye", 10, 'Sigue siendo necesario.'),
      FakeRating('Songs in the Key of Life Stevie Wonder', 9),
    ],
    favorites: ['Kind of Blue Miles Davis', "Voodoo D'Angelo", "What's Going On Marvin Gaye"],
    favoriteArtists: ['Miles Davis', "D'Angelo", 'John Coltrane'],
    rankingFrom: 'Kind of Blue Miles Davis',
    rankingName: 'Kind of Blue, en orden de preferencia',
    rankingSeed: 3,
    albumListName: 'Para un domingo en casa',
    albumList: [
      "Mama's Gun Erykah Badu",
      'Blue Train John Coltrane',
      'Mingus Ah Um Charles Mingus',
      'Songs in the Key of Life Stevie Wonder',
    ],
  ),
  FakePerson(
    email: 'laura.gomez@vinilo.test',
    name: 'Laura Gómez',
    username: 'lauragomez.mp3',
    colorValue: 0xFF5FA8D3,
    ratings: [
      FakeRating('To Pimp a Butterfly Kendrick Lamar', 10, 'Denso, político y con el mejor jazz del rap.'),
      FakeRating('good kid, m.A.A.d city Kendrick Lamar', 9),
      FakeRating('Channel ORANGE Frank Ocean', 9, 'El verano en un disco.'),
      FakeRating('SOS SZA', 8, '"Kill Bill" no sale de mi cabeza.'),
      FakeRating('Ctrl SZA', 9),
      FakeRating('The Miseducation of Lauryn Hill Lauryn Hill', 10, 'Atemporal.'),
      FakeRating('Mr. Morale & The Big Steppers Kendrick Lamar', 7, 'Me costó entrarle, pero vale la pena.'),
      FakeRating('IGOR Tyler, The Creator', 8),
      FakeRating('Flower Boy Tyler, The Creator', 8, 'Tyler mostrando su lado más suave.'),
      FakeRating('Madvillainy Madvillain', 9),
      FakeRating('4:44 JAY-Z', 7),
      FakeRating('Heaux Tales Jazmine Sullivan', 8),
    ],
    favorites: [
      'To Pimp a Butterfly Kendrick Lamar',
      'The Miseducation of Lauryn Hill Lauryn Hill',
      'Ctrl SZA',
    ],
    favoriteArtists: ['Kendrick Lamar', 'SZA', 'Frank Ocean'],
    rankingFrom: 'To Pimp a Butterfly Kendrick Lamar',
    rankingName: 'To Pimp a Butterfly, de la mejor a la peor',
    rankingSeed: 17,
    albumListName: 'R&B para la noche',
    albumList: [
      'Ctrl SZA',
      'SOS SZA',
      'Channel ORANGE Frank Ocean',
      'Heaux Tales Jazmine Sullivan',
    ],
  ),
  FakePerson(
    email: 'mateo.salazar@vinilo.test',
    name: 'Mateo Salazar',
    username: 'mateo.salazar',
    colorValue: 0xFF8DBB7A,
    ratings: [
      FakeRating('Discovery Daft Punk', 10, 'El disco más feliz que existe.'),
      FakeRating('Random Access Memories Daft Punk', 8),
      FakeRating('Amanecer Bomba Estéreo', 8, 'Suena a Colombia de fiesta.'),
      FakeRating('Un Verano Sin Ti Bad Bunny', 9, 'Lo puse todo el verano, ni modo.'),
      FakeRating('YHLQMDLG Bad Bunny', 8),
      FakeRating('Currents Tame Impala', 9, 'Sintetizadores perfectos para manejar.'),
      FakeRating('Since I Left You The Avalanches', 9),
      FakeRating('Immunity Jon Hopkins', 8),
      FakeRating('Singularity Jon Hopkins', 7),
      FakeRating('Cross Justice', 8, 'Todavía suena moderno.'),
      FakeRating('Plastic Beach Gorillaz', 8),
      FakeRating('Deja Bomba Estéreo', 7),
    ],
    favorites: ['Discovery Daft Punk', 'Currents Tame Impala', 'Un Verano Sin Ti Bad Bunny'],
    favoriteArtists: ['Daft Punk', 'Bad Bunny', 'Bomba Estéreo'],
    rankingFrom: 'Discovery Daft Punk',
    rankingName: 'Discovery, canción por canción',
    rankingSeed: 29,
    albumListName: 'Para la pista',
    albumList: [
      'Discovery Daft Punk',
      'Cross Justice',
      'Since I Left You The Avalanches',
      'Amanecer Bomba Estéreo',
    ],
  ),
];
