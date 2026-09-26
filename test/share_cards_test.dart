import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/affinity.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/artist.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/music_list.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/user_profile.dart';
import 'package:no_retiene/share_cards/album_card.dart';
import 'package:no_retiene/share_cards/artist_card.dart';
import 'package:no_retiene/share_cards/friend_card.dart';
import 'package:no_retiene/share_cards/list_card.dart';
import 'package:no_retiene/share_cards/profile_card.dart';
import 'package:no_retiene/share_cards/share_card_data.dart';
import 'package:no_retiene/share_cards/share_specs.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

const _long = 'Un título larguísimo que no cabe de ninguna manera en una sola línea de la tarjeta';
const _person = CardPerson(name: 'Mateo Salazar Restrepo', handle: '@mateo.salazar.restrepo', color: Color(0xFF4990E8));
const _me = CardPerson(name: 'Manuel', handle: '@manuel', color: Color(0xFFFD6A3A));

RatingEntry _rating(
  String album,
  int score, {
  DateTime? at,
  String note = '',
  List<String> artistIds = const ['art'],
  String name = '',
}) {
  final when = at ?? DateTime(2026, 9, 25);
  return RatingEntry(
    id: 'yo_$album',
    uid: 'yo',
    albumId: album,
    score: score,
    note: note,
    createdAt: when,
    updatedAt: when,
    album: Album(id: album, name: name.isEmpty ? album : name, artist: 'Artista', artistIds: artistIds, year: 2026),
    user: const RaterInfo(uid: 'yo', name: 'Manuel', colorValue: 0xFFFD6A3A),
  );
}

CommonAlbum _common(String id, int mine, int theirs, {int day = 1}) => CommonAlbum(
      album: Album(id: id, name: id, artist: 'x'),
      mine: mine,
      theirs: theirs,
      at: DateTime(2026, 9, day),
    );

MusicList _list({int items = 3, ListItemType type = ListItemType.albums, List<String?>? covers}) => MusicList(
      id: 'l',
      ownerUid: 'u',
      owner: const PersonInfo(uid: 'u', name: 'Camila', colorValue: 0xFFFD6A3A, username: 'camila'),
      name: _long,
      description: '',
      kind: ListKind.list,
      itemType: type,
      items: [
        for (var i = 0; i < items; i++)
          ListItem(id: 'i$i', name: 'n$i', artist: 'a', coverSmall: covers == null ? 'c$i' : covers[i % covers.length]),
      ],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      savedBy: const ['a', 'b'],
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('datos', () {
    test('la regla: la elegida entera y opaca, las demás bajan y se apagan', () {
      expect(cardRulerCell(9, 9), (height: 1.0, opacity: 1.0));
      final one = cardRulerCell(8, 9);
      expect(one.height, closeTo(0.66, 1e-9));
      expect(one.opacity, closeTo(0.62, 1e-9));
      final far = cardRulerCell(1, 9);
      expect(far.height, closeTo(0.22, 1e-9));
      expect(far.opacity, closeTo(0.16, 1e-9));
    });

    test('la rejilla de la lista repite portadas si son pocas y deja vacío lo que no hay', () {
      final oneAlbum = listGridCovers(_list(items: 3, covers: ['x']), 9);
      expect(oneAlbum.take(3), ['x', 'x', 'x']);
      expect(oneAlbum.skip(3).every((c) => c == null), isTrue);
      final many = listGridCovers(_list(items: 20), 9);
      expect(many, ['c0', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8']);
      expect(listGridCovers(_list(items: 20), 4).length, 4);
    });

    test('mi semana: solo los últimos 7 días, lo más reciente primero y hasta 5 filas', () {
      final now = DateTime(2026, 9, 21, 18);
      final week = weekCardFrom([
        _rating('viejo', 5, at: DateTime(2026, 9, 14, 23)),
        for (var d = 15; d <= 21; d++) _rating('d$d', 7, at: DateTime(2026, 9, d, 10)),
      ], now: now, person: _me)!;
      expect(week.count, 7);
      expect(week.rows.length, 5);
      expect(week.rows.first.albumId, 'd21');
      expect(week.from, DateTime(2026, 9, 15));
      expect(weekCardFrom([_rating('viejo', 5, at: DateTime(2026, 9, 1))], now: now, person: _me), isNull);
    });

    test('el rango de la semana', () {
      expect(weekRange(DateTime(2026, 9, 15), DateTime(2026, 9, 21), 'es'), '15–21 sept');
      expect(weekRange(DateTime(2026, 9, 28), DateTime(2026, 10, 4), 'en'), '28 Sep – 4 Oct');
    });

    test('amigo: 2 coincidencias y la mayor diferencia', () {
      final rows = friendRows([
        _common('igual', 8, 8, day: 3),
        _common('casi', 7, 8),
        _common('lejos', 2, 9),
        _common('medio', 5, 8),
      ]);
      expect([for (final r in rows) r.album.album.id], ['igual', 'casi', 'lejos']);
      expect([for (final r in rows) r.agree], [true, true, false]);
    });

    test('amigo: si coincidimos en todo, las 3 son coincidencias', () {
      final rows = friendRows([_common('a', 8, 8), _common('b', 5, 5), _common('c', 9, 9), _common('d', 1, 1)]);
      expect(rows.length, 3);
      expect(rows.every((r) => r.agree), isTrue);
      expect(friendRows([_common('solo', 3, 9)]).single.agree, isTrue);
    });

    test('amigo: sin discos en común no hay tarjeta; la frase depende del porcentaje', () {
      expect(friendCardFrom(percent: null, albums: const [], me: _me, friend: _person), isNull);
      expect(friendVerdict(80), FriendVerdict.almostAll);
      expect(friendVerdict(79), FriendVerdict.quiteALot);
      expect(friendVerdict(50), FriendVerdict.quiteALot);
      expect(friendVerdict(49), FriendVerdict.opposites);
    });

    test('artista: el promedio cuenta solo mis notas de sus discos, sin repetir', () {
      const artist = Artist(id: 'art', name: 'Los Satélites');
      final card = artistCardFrom(
        artist: artist,
        myRatings: [
          _rating('a', 9),
          _rating('b', 8),
          _rating('b', 2),
          _rating('ajeno', 1, artistIds: const ['otro']),
          _rating('c', 6),
          _rating('d', 10),
        ],
        totalAlbums: 5,
        person: _me,
      )!;
      expect(card.rated, 4);
      expect(card.total, 5);
      expect(card.average, closeTo((9 + 8 + 6 + 10) / 4, 1e-9));
      expect([for (final r in card.top) r.albumId], ['d', 'a', 'b']);
      expect(
        artistCardFrom(artist: artist, myRatings: [_rating('x', 5, artistIds: const ['otro'])], totalAlbums: 3, person: _me),
        isNull,
      );
    });

    test('reseñas: solo las notas con comentario', () {
      expect(reviewsIn([_rating('a', 5, note: 'hola'), _rating('b', 5, note: '  '), _rating('c', 5)]), 1);
    });

    test('la persona: su @ o su nombre, y el primer nombre', () {
      expect(_person.firstName, 'Mateo');
      expect(const CardPerson(name: 'Ana', handle: '', color: Color(0xFF000000)).label, 'Ana');
    });
  });

  group('qué tarjetas ofrece cada pantalla', () {
    const accent = ViniloPalette.defaultAccent;

    test('disco: historia y cuadrado; hilo con comentario: solo la reseña', () {
      expect(ShareSpecs.album(_rating('a', 8), person: _me, accent: accent).single.square, isTrue);
      final review = ShareSpecs.rating(_rating('a', 8, note: 'hola'), person: _me, accent: accent);
      expect(review.single.square, isFalse);
      expect(ShareSpecs.rating(_rating('a', 8), person: _me, accent: accent).single.square, isTrue);
    });

    test('mi perfil suma "mi semana" solo si califiqué algo en 7 días', () {
      final profile = UserProfile(uid: 'yo', name: 'Manuel', colorValue: 0xFFFD6A3A, createdAt: DateTime(2025));
      final now = DateTime(2026, 9, 25, 12);
      expect(ShareSpecs.myProfile(profile, [_rating('a', 8, at: DateTime(2026, 9, 24))], accent: accent, now: now).length, 2);
      expect(ShareSpecs.myProfile(profile, [_rating('a', 8, at: DateTime(2026, 8, 1))], accent: accent, now: now).length, 1);
    });

    test('sin datos no hay tarjeta (se comparte solo el enlace)', () {
      expect(ShareSpecs.artist(null, accent: accent), isEmpty);
      expect(ShareSpecs.friend(null, accent: accent), isEmpty);
    });
  });

  group('las tarjetas se montan sin desbordes', () {
    for (final locale in const ['es', 'en']) {
      Future<void> pump(WidgetTester tester, Widget card) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildViniloTheme(ViniloPalette.light),
          home: Center(child: card),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      const accent = ViniloPalette.defaultAccent;
      final longRating = _rating('a', 10, name: _long, note: 'x' * 180);

      testWidgets('disco, historia y cuadrado ($locale)', (tester) async {
        final data = AlbumCardData.fromRating(longRating, person: _person);
        await pump(tester, AlbumShareCard(data: data, accent: accent));
        expect(tester.getSize(find.byType(AlbumShareCard)), const Size(360, 640));
        await pump(tester, AlbumShareCard(data: data, accent: accent, format: ShareCardFormat.square));
        expect(tester.getSize(find.byType(AlbumShareCard)), const Size(360, 360));
      });

      testWidgets('reseña con 180 letras ($locale)', (tester) async {
        await pump(tester, ReviewShareCard(data: AlbumCardData.fromRating(longRating, person: _person), accent: accent));
      });

      testWidgets('lista y ranking de canciones ($locale)', (tester) async {
        await pump(tester, ListShareCard(list: _list(items: 24, type: ListItemType.tracks), accent: accent));
        await pump(tester, ListShareCard(list: _list(items: 2), accent: accent, format: ShareCardFormat.square));
      });

      testWidgets('artista ($locale)', (tester) async {
        final data = artistCardFrom(
          artist: const Artist(id: 'art', name: 'Un Nombre De Artista Muy Largo Para Probar'),
          myRatings: [for (var i = 0; i < 4; i++) _rating('a$i', 7 + i % 3, name: _long)],
          totalAlbums: 40,
          person: _person,
        )!;
        await pump(tester, ArtistShareCard(data: data, accent: accent));
      });

      testWidgets('mi perfil y mi semana ($locale)', (tester) async {
        final profile = UserProfile(
          uid: 'yo',
          name: 'Manuela Castillo de la Torre Ramírez',
          username: 'manuela.castillo.largo',
          colorValue: 0xFFFD6A3A,
          createdAt: DateTime(2025, 3, 1),
          ratingsCount: 1312,
          ratingsSum: 9000,
          favorites: [for (var i = 0; i < 3; i++) Album(id: 'f$i', name: 'f$i', artist: 'a')],
        );
        await pump(tester, ProfileShareCard(data: ProfileCardData(profile: profile, reviews: 480), accent: accent));
        final week = weekCardFrom(
          [for (var d = 15; d <= 21; d++) _rating('d$d', 10, at: DateTime(2026, 9, d), name: _long)],
          now: DateTime(2026, 9, 21, 12),
          person: _person,
        )!;
        await pump(tester, WeekShareCard(data: week, accent: accent));
      });

      testWidgets('amigo ($locale)', (tester) async {
        final data = friendCardFrom(
          percent: 100,
          albums: [_common(_long, 8, 8), _common('b', 7, 8), _common('c', 1, 10)],
          me: _me,
          friend: _person,
        )!;
        await pump(tester, FriendShareCard(data: data, accent: accent));
      });
    }
  });
}
