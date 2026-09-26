import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/screens/welcome_screen.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

Widget _app(Widget child) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 38), child: child),
        ),
      ),
    );

Widget _bare(Widget child) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  Future<void> mount(WidgetTester tester, {VoidCallback? onSignUp, VoidCallback? onSignIn}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(WelcomeActions(
      onSignUp: onSignUp ?? () {},
      onSignIn: onSignIn ?? () {},
    )));
  }

  testWidgets('arranca con las barras y sin botones que se puedan tocar', (tester) async {
    await mount(tester);
    expect(_key('welcome-bars').hitTestable(), findsOneWidget);
    expect(_key('welcome-invite'), findsOneWidget);
    // La demostración arranca en 8 y va pasando sola.
    expect(find.descendant(of: _key('welcome-score'), matching: find.text('8')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.descendant(of: _key('welcome-score'), matching: find.text('3')), findsOneWidget);
    expect(_key('welcome-signup').hitTestable(), findsNothing);
    expect(_key('welcome-signin').hitTestable(), findsNothing);
  });

  testWidgets('al tocar una barra se ve la nota y después suben los botones', (tester) async {
    var signUps = 0;
    await mount(tester, onSignUp: () => signUps++);
    final slot = tester.getRect(find.byType(WelcomeActions));

    await tester.tap(_key('dial-7'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getRect(find.byType(WelcomeActions)), slot);
    // Durante la espera se ven la nota y su veredicto, y aún no hay botones.
    expect(find.descendant(of: _key('welcome-score'), matching: find.text('7')), findsOneWidget);
    expect(find.text('BUENO'), findsOneWidget);
    expect(_key('welcome-signup').hitTestable(), findsNothing);

    await tester.pumpAndSettle();
    expect(_key('welcome-signup').hitTestable(), findsOneWidget);
    expect(_key('welcome-signin').hitTestable(), findsOneWidget);
    expect(_key('welcome-bars').hitTestable(), findsNothing);
    // El hueco no cambia: lo de arriba no se mueve.
    expect(tester.getRect(find.byType(WelcomeActions)), slot);

    await tester.tap(_key('welcome-signup'));
    expect(signUps, 1);
  });

  testWidgets('arrastrar también cuenta, al soltar', (tester) async {
    await mount(tester);
    final start = tester.getCenter(_key('dial-2'));
    final end = tester.getCenter(_key('dial-9'));
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(Offset.lerp(start, end, 0.5)!);
    await gesture.moveTo(end);
    await tester.pump(const Duration(seconds: 2));
    // Con el dedo todavía encima no pasa nada.
    expect(_key('welcome-signup').hitTestable(), findsNothing);
    expect(find.descendant(of: _key('welcome-score'), matching: find.text('9')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_key('welcome-signin').hitTestable(), findsOneWidget);
  });

  testWidgets('dentro de la bienvenida real (SliverFillRemaining) no falla', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_bare(CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 575),
              const SizedBox(height: 22),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 38),
                child: WelcomeActions(onSignUp: () {}, onSignIn: () {}),
              ),
            ],
          ),
        ),
      ],
    )));
    expect(tester.takeException(), isNull);
    // La 8 es la que muestra la demostración: tocarla igual cuenta.
    await tester.tap(_key('dial-8'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_key('welcome-signup').hitTestable(), findsOneWidget);
  });
}
