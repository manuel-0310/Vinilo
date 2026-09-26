import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/album_strip.dart';

Widget _app(Widget child) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Align(alignment: Alignment.topCenter, child: child)),
    );

const _albums = [
  Album(
    id: 'a1',
    name: 'Un Verano Sin Ti (Edición de lujo con todas las canciones extra)',
    artist: 'Bad Bunny, Chencho Corleone, Bomba Estéreo y muchos más invitados',
    year: 2022,
  ),
  // Letras que Archivo no tiene: se dibujan con otra fuente.
  Album(id: 'a2', name: '東京事変 · 大人 🎷', artist: '椎名林檎 ♫ 東京事変', year: 2006),
  Album(id: 'a3', name: 'OK Computer', artist: 'Radiohead', year: 1997),
];

void main() {
  setUpAll(() async {
    final archivo = FontLoader(VText.archivo)..addFont(rootBundle.load('assets/fonts/Archivo-Variable.ttf'));
    await archivo.load();
  });

  for (final yearOnly in [false, true]) {
    testWidgets('AlbumStrip no se desborda con textos largos (yearOnly: $yearOnly)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(AlbumStrip(
        albums: _albums,
        heroPrefix: 't',
        yearOnly: yearOnly,
        averages: yearOnly ? const {} : const {'a1': 9, 'a2': 10, 'a3': 7.5},
      )));
      expect(tester.takeException(), isNull);

      // Cada línea mide lo mismo aunque traiga otra fuente (el motor
      // redondea el alto de la línea al píxel).
      double heightOf(String text) => tester.renderObject<RenderBox>(find.text(text)).size.height;
      final latin = heightOf(_albums[2].name);
      expect(heightOf(_albums[1].name), latin);
      expect(latin, moreOrLessEquals(AlbumTile.lineHeight(14), epsilon: 0.5));
      expect(AlbumStrip.heightFor(136), 175);
    });
  }

  testWidgets('el esqueleto cabe en el mismo alto', (tester) async {
    await tester.pumpWidget(_app(const AlbumStripSkeleton()));
    expect(tester.takeException(), isNull);
    // El latido del esqueleto deja un temporizador: desmontarlo y dejarlo
    // correr.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
