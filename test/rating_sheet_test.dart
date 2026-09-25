import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/rating_sheet.dart';
import 'package:no_retiene/widgets/v_buttons.dart';

Widget _app(Widget child) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
    );

const _album = Album(id: 'a1', name: 'Bocanada', artist: 'Gustavo Cerati', year: 1999);

void main() {
  testWidgets('la primera vez no hay nota: "—" y guardar apagado', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const RatingSheet(album: _album)));
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Gustavo Cerati · 1999'), findsOneWidget);
    final save = tester.widget<VPrimaryButton>(find.byKey(const ValueKey('rating-save')));
    expect(save.onPressed, isNull);
    // Sin nota no hay "Borrar nota".
    expect(find.byKey(const ValueKey('rating-delete')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dial-9')));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsWidgets);
    expect(find.text('Excelente'), findsOneWidget);
    final enabled = tester.widget<VPrimaryButton>(find.byKey(const ValueKey('rating-save')));
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('al editar arranca en la nota elegida', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const RatingSheet(album: _album, initialScore: 7)));
    expect(find.text('Bueno'), findsOneWidget);
    expect(find.text('Guardar mi nota'), findsOneWidget);
  });
}
