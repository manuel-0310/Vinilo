import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/services/share_service.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/share_sheet.dart';

ShareCardSpec _spec({bool square = false, Color color = const Color(0xFF336699)}) => ShareCardSpec(
      square: square,
      build: (format, _) => SizedBox.fromSize(size: format.size, child: ColoredBox(color: color)),
    );

Widget _app(List<ShareCardSpec> cards) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildViniloTheme(ViniloPalette.dark),
      home: Scaffold(
        body: ShareSheet(
          cards: cards,
          message: (_) => (text: 'Mira', url: Uri.parse('https://red-social-c786b.web.app/d/x')),
        ),
      ),
    );

void main() {
  const channel = MethodChannel('vinilo/share');
  final calls = <MethodCall>[];

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  void mockChannel(Object? Function(MethodCall call) reply) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final r = reply(call);
      if (r is PlatformException) throw r;
      return r;
    });
  }

  /// La captura espera el fin de un cuadro y trabaja fuera del reloj falso
  /// de las pruebas: se alternan cuadros y espera real.
  Future<void> settleCapture(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    }
    await tester.pump();
  }

  Future<void> pump(WidgetTester tester, List<ShareCardSpec> cards) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(cards));
    await tester.pumpAndSettle();
  }

  group('ShareService', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('shareImage manda la imagen, el texto y el enlace', () async {
      mockChannel((_) => true);
      await ShareService.shareImage(Uint8List.fromList([1, 2, 3]), 'Mira', Uri.parse('https://x.y/d/1'));
      expect(calls.single.method, 'shareImage');
      final args = calls.single.arguments as Map;
      expect(args['png'], [1, 2, 3]);
      expect(args['text'], 'Mira');
      expect(args['url'], 'https://x.y/d/1');
    });

    test('sin App ID de Meta, en iOS las historias ni se intentan', () async {
      mockChannel((_) => true);
      expect(await ShareService.instagramStory(Uint8List(1)), isFalse);
      expect(calls, isEmpty);
    });

    test('guardar sin permiso da un error tipado', () async {
      mockChannel((_) => PlatformException(code: 'denied'));
      await expectLater(
        ShareService.saveImage(Uint8List(1)),
        throwsA(isA<ShareImageException>().having((e) => e.error, 'error', ShareImageError.denied)),
      );
    });

    test('sin canal, no se puede', () async {
      await expectLater(
        ShareService.saveImage(Uint8List(1)),
        throwsA(isA<ShareImageException>().having((e) => e.error, 'error', ShareImageError.unsupported)),
      );
    });
  });

  group('ShareSheet', () {
    testWidgets('historia y cuadrado: las pestañas y el botón cambian', (tester) async {
      await pump(tester, [_spec(square: true)]);
      expect(find.byKey(const ValueKey('share-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-preview')), findsOneWidget);
      for (final k in ['share-target-story', 'share-target-whatsapp', 'share-target-save', 'share-target-link']) {
        expect(find.byKey(ValueKey(k)), findsOneWidget);
      }
      expect(find.text('Compartir en Historias'), findsOneWidget);
      // Vista previa a 0,6 como mucho (216×384), en 9:16. (La letra de las
      // pruebas es más ancha que Archivo y el título ocupa más, así que aquí
      // queda algo más chica.)
      final story = tester.getSize(find.byType(FittedBox));
      expect(story.width, lessThanOrEqualTo(216));
      expect(story.height / story.width, closeTo(640 / 360, 0.01));

      await tester.tap(find.byKey(const ValueKey('share-tab-square')));
      await tester.pumpAndSettle();
      expect(find.text('Compartir imagen'), findsOneWidget);
      final square = tester.getSize(find.byType(FittedBox));
      expect(square.width, lessThanOrEqualTo(216));
      expect(square.width, closeTo(square.height, 0.5));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('sin cuadrado no hay pestañas', (tester) async {
      await pump(tester, [_spec()]);
      expect(find.byKey(const ValueKey('share-tab-square')), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('dos tarjetas: se deslizan con dos puntos', (tester) async {
      await pump(tester, [_spec(), _spec(color: const Color(0xFF993322))]);
      expect(find.byType(PageView), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('guardar avisa "Imagen guardada" con la imagen a 3×', (tester) async {
      mockChannel((_) => true);
      await pump(tester, [_spec()]);
      await tester.tap(find.byKey(const ValueKey('share-target-save')));
      await settleCapture(tester);
      expect(calls.single.method, 'saveImage');
      final png = (calls.single.arguments as Map)['png'] as Uint8List;
      // Cabecera PNG: ancho y alto a 3× (1080×1920).
      final data = ByteData.sublistView(png);
      expect(data.getUint32(16), 1080);
      expect(data.getUint32(20), 1920);
      expect(find.text('IMAGEN GUARDADA'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('guardar sin permiso lo explica', (tester) async {
      mockChannel((_) => PlatformException(code: 'denied'));
      await pump(tester, [_spec()]);
      await tester.tap(find.byKey(const ValueKey('share-target-save')));
      await settleCapture(tester);
      expect(find.textContaining('no tiene permiso'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
