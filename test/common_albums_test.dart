import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/affinity.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/screens/profile_header.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

List<CommonAlbum> _albums(int n) => [
      for (var i = 0; i < n; i++)
        CommonAlbum(
          album: Album(id: 'a$i', name: 'Disco $i', artist: 'x'),
          mine: 8,
          theirs: 9,
          at: DateTime(2026, 9, 25),
        ),
    ];

Widget _app(Widget child, double width) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: child))),
    );

void main() {
  group('CommonAlbumsRow.layout', () {
    test('hasta 6 caben todas sin "+N"', () {
      expect(CommonAlbumsRow.layout(4, 8), (shown: 4, more: 0));
      expect(CommonAlbumsRow.layout(6, 8), (shown: 6, more: 0));
    });

    test('con más de 6, 6 portadas y "+N"', () {
      expect(CommonAlbumsRow.layout(9, 8), (shown: 6, more: 3));
      expect(CommonAlbumsRow.layout(7, 7), (shown: 6, more: 1));
    });

    test('si no caben, las que caben y la última celda es "+N"', () {
      expect(CommonAlbumsRow.layout(9, 5), (shown: 4, more: 5));
      expect(CommonAlbumsRow.layout(5, 5), (shown: 5, more: 0));
      expect(CommonAlbumsRow.layout(6, 5), (shown: 4, more: 2));
    });
  });

  testWidgets('a lo ancho del perfil: 6 portadas de 40 y "+3"', (tester) async {
    await tester.pumpWidget(_app(CommonAlbumsRow(albums: _albums(9)), 362));
    for (var i = 0; i < 6; i++) {
      expect(tester.getSize(find.byKey(ValueKey('common-album-$i'))), const Size(40, 40));
    }
    expect(find.byKey(const ValueKey('common-album-6')), findsNothing);
    expect(find.byKey(const ValueKey('common-more')), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey('common-album-1'))).dx, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con pocas, sin "+N"', (tester) async {
    await tester.pumpWidget(_app(CommonAlbumsRow(albums: _albums(2)), 362));
    expect(find.byKey(const ValueKey('common-album-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('common-more')), findsNothing);
  });
}
