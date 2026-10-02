import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/onboarding.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/user_profile.dart';
import 'package:no_retiene/screens/onboarding_tastes_screen.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

Album _album(String id, {String artist = 'x', String? type = 'album'}) =>
    Album(id: id, name: 'Disco $id', artist: artist, type: type);

RatingEntry _rating(String uid, String album, int score, {int day = 1}) => RatingEntry(
      id: RatingEntry.docId(uid, album),
      uid: uid,
      albumId: album,
      score: score,
      note: '',
      createdAt: DateTime(2026, 9, day),
      updatedAt: DateTime(2026, 9, day),
      album: Album(id: album, name: 'Disco $album', artist: 'x'),
      user: RaterInfo(uid: uid, name: uid, colorValue: 0xFF000000),
    );

void main() {
  group('selección por género', () {
    test('cada filtro tiene sus 12 discos, sin repetir dentro del filtro', () {
      for (final genre in TasteGenre.values) {
        final seeds = tasteSeeds[genre];
        expect(seeds, isNotNull, reason: '$genre');
        expect(seeds!.length, tasteGridSize, reason: '$genre');
        expect({for (final s in seeds) '${s.album}|${s.artist}'}.length, seeds.length, reason: '$genre');
        for (final s in seeds) {
          expect(s.album.trim(), isNotEmpty);
          expect(s.artist.trim(), isNotEmpty);
        }
      }
    });

    test('los filtros empiezan por Populares y tienen nombre en los dos idiomas', () {
      expect(TasteGenre.values.first, TasteGenre.popular);
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
        [for (final g in TasteGenre.values.take(5)) g.label(es)],
        ['Populares', 'Rock', 'Pop latino', 'Hip hop', 'Electrónica'],
      );
      for (final g in TasteGenre.values) {
        expect(g.label(en), isNotEmpty);
      }
    });

    test('la búsqueda de una semilla usa los filtros de campo de Spotify', () {
      expect(
        seedQuery((album: 'OK Computer', artist: 'Radiohead')),
        'album:OK Computer artist:Radiohead',
      );
    });

    test('de los resultados se queda con el álbum de ese artista', () {
      const seed = (album: 'Blonde', artist: 'Frank Ocean');
      final single = _album('s', artist: 'Frank Ocean', type: 'single');
      final other = _album('o', artist: 'Otro');
      final right = _album('r', artist: 'Frank Ocean');
      expect(pickSeedResult(seed, [single, other, right])?.id, 'r');
      // Sin álbum de ese artista, el primer álbum; sin álbumes, lo primero.
      expect(pickSeedResult(seed, [single, other])?.id, 'o');
      expect(pickSeedResult(seed, [single])?.id, 's');
      expect(pickSeedResult(seed, const []), isNull);
    });

    test('junta comunidad y selección sin repetir y recorta', () {
      final merged = mergeTasteAlbums(
        [_album('a'), _album('b')],
        [_album('b'), null, _album('c'), _album('d')],
        limit: 3,
      );
      expect(merged.map((a) => a.id), ['a', 'b', 'c']);
    });
  });

  group('elegir discos', () {
    test('entra al final, sale al tocarlo otra vez y los demás suben', () {
      var picked = <Album>[];
      picked = toggleTaste(picked, _album('a'), max: 9);
      picked = toggleTaste(picked, _album('b'), max: 9);
      picked = toggleTaste(picked, _album('c'), max: 9);
      expect(picked.map((a) => a.id), ['a', 'b', 'c']);
      picked = toggleTaste(picked, _album('a'), max: 9);
      expect(picked.map((a) => a.id), ['b', 'c']);
    });

    test('con el máximo no entra otro (y la lista es la misma)', () {
      final full = [_album('a'), _album('b')];
      expect(identical(toggleTaste(full, _album('c'), max: 2), full), isTrue);
      // Pero sí se puede quitar uno.
      expect(toggleTaste(full, _album('a'), max: 2).map((a) => a.id), ['b']);
    });

    test('se necesitan 3 para continuar', () {
      expect(tastesRequired, 3);
    });

    testWidgets('tocar una portada le pone su número de orden y tocarla de nuevo lo quita',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final albums = [for (final id in ['a', 'b', 'c', 'd']) _album(id)];
      var picked = <Album>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildViniloTheme(ViniloPalette.dark),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TasteGrid(
                albums: albums,
                picked: picked,
                onToggle: (a) => setState(() => picked = toggleTaste(picked, a, max: 9)),
              ),
            ),
          ),
        ),
      );
      expect(find.text('1'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('taste-2')));
      await tester.tap(find.byKey(const ValueKey('taste-0')));
      await tester.pump();
      expect(picked.map((a) => a.id), ['c', 'a']);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('taste-2')));
      await tester.pump();
      // El que quedaba pasa a ser el primero.
      expect(picked.map((a) => a.id), ['a']);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('a quién seguir', () {
    const tastes = {'a1', 'a2', 'a3'};

    test('la afinidad es su nota media sobre mis discos y el motivo, su mejor nota', () {
      final out = suggestByTastes(
        [
          _rating('santi', 'a1', 10),
          _rating('santi', 'a2', 8),
          _rating('vale', 'a3', 9),
          _rating('vale', 'zz', 2), // No es de mis discos: no cuenta.
        ],
        tasteIds: tastes,
      );
      expect(out.map((s) => s.person.uid), ['santi', 'vale']);
      expect(out[0].percent, 90);
      expect(out[0].reason, SuggestionReason.sameTen);
      expect(out[0].album?.id, 'a1');
      expect(out[0].matched, 2);
      expect(out[1].percent, 90);
      expect(out[1].reason, SuggestionReason.rated);
      expect(out[1].score, 9);
    });

    test('a igual afinidad va primero quien coincide en más discos', () {
      final out = suggestByTastes(
        [
          _rating('uno', 'a1', 9),
          _rating('dos', 'a1', 9),
          _rating('dos', 'a2', 9),
        ],
        tasteIds: tastes,
      );
      expect(out.map((s) => s.person.uid), ['dos', 'uno']);
    });

    test('quien les puso menos de 6 a mis discos no se sugiere', () {
      final out = suggestByTastes(
        [_rating('hater', 'a1', 3), _rating('tibio', 'a1', 6)],
        tasteIds: tastes,
      );
      expect(out.map((s) => s.person.uid), ['tibio']);
      expect(out.single.percent, suggestionMinPercent);
    });

    test('nunca me sugiere a mí ni a quien está excluido, y respeta el tope', () {
      final out = suggestByTastes(
        [
          _rating('yo', 'a1', 10),
          _rating('bloqueada', 'a1', 10),
          for (var i = 0; i < 12; i++) _rating('p$i', 'a1', 10),
        ],
        tasteIds: tastes,
        exclude: {'yo', 'bloqueada'},
        limit: 5,
      );
      expect(out, hasLength(5));
      expect(out.any((s) => s.person.uid == 'yo' || s.person.uid == 'bloqueada'), isFalse);
    });

    test('las cuentas populares completan, sin repetir a nadie', () {
      final byTaste = suggestByTastes([_rating('santi', 'a1', 10)], tasteIds: tastes);
      PersonInfo person(String uid) => PersonInfo(uid: uid, name: uid, colorValue: 0xFF000000);
      final out = fillWithPopular(
        byTaste,
        [
          (person: person('santi'), followers: 50),
          (person: person('tomas'), followers: 1200),
          (person: person('yo'), followers: 3),
          (person: person('lucia'), followers: 40),
        ],
        exclude: {'yo'},
        limit: 3,
      );
      expect(out.map((s) => s.person.uid), ['santi', 'tomas', 'lucia']);
      expect(out[1].reason, SuggestionReason.popular);
      expect(out[1].percent, isNull);
    });

    test('el motivo se dice en el idioma de la app', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      final ten = suggestByTastes([_rating('santi', 'a1', 10)], tasteIds: tastes).single;
      expect(ten.reasonText(es), 'También le puso 10 a Disco a1');
      expect(ten.reasonText(en), 'Also gave Disco a1 a 10');
      final nine = suggestByTastes([_rating('diego', 'a2', 9)], tasteIds: tastes).single;
      expect(nine.reasonText(es), 'Calificó Disco a2 con 9');
      const popular = PeopleSuggestion(
        person: PersonInfo(uid: 't', name: 'Tomás', colorValue: 0xFF000000),
        reason: SuggestionReason.popular,
        followers: 1,
      );
      expect(popular.reasonText(es), 'Popular en Vinilo · 1 seguidor');
    });
  });

  test('los pasos del onboarding van y vuelven por su clave', () {
    expect(OnboardingStep.fromKey('tastes'), OnboardingStep.tastes);
    expect(OnboardingStep.fromKey('follow'), OnboardingStep.follow);
    // Las cuentas de antes no tienen el campo: ya lo terminaron.
    expect(OnboardingStep.fromKey(null), isNull);
    expect(OnboardingStep.fromKey('otra-cosa'), isNull);
  });
}
