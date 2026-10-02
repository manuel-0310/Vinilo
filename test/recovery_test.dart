import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/screens/recover_password_screen.dart';
import 'package:no_retiene/services/recovery_service.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/line_field.dart';
import 'package:no_retiene/widgets/v_sections.dart';

final _endpoint = Uri.parse('https://us-central1-x.cloudfunctions.net/recover');

RecoveryService _service(Future<http.Response> Function(http.Request) handler) =>
    RecoveryService.at(_endpoint, client: MockClient(handler));

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Widget _app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('RecoveryService', () {
    test('la función vive junto a la de Spotify', () {
      expect(
        RecoveryService.endpointFrom(
          override: '',
          spotifyUrl: 'https://us-central1-x.cloudfunctions.net/spotify',
        ),
        _endpoint,
      );
      expect(RecoveryService.endpointFrom(override: '', spotifyUrl: ''), isNull);
      expect(
        RecoveryService.endpointFrom(override: 'https://otra.test/r', spotifyUrl: ''),
        Uri.parse('https://otra.test/r'),
      );
    });

    test('start manda el correo y el idioma, y dice cuándo se puede reenviar', () async {
      late http.Request seen;
      final service = _service((req) async {
        seen = req;
        return _json(200, {'ok': true, 'resendIn': 45, 'expiresIn': 600});
      });
      expect(await service.start(' manuel@correo.com ', lang: 'es'), 45);
      expect(seen.method, 'POST');
      expect(seen.url.path, '/recover/start');
      expect(jsonDecode(seen.body), {'email': 'manuel@correo.com', 'lang': 'es'});
    });

    test('verify devuelve el ticket y finish, el nombre', () async {
      final service = _service((req) async {
        if (req.url.path.endsWith('/verify')) return _json(200, {'ok': true, 'ticket': 'abc'});
        expect(jsonDecode(req.body), {
          'email': 'manuel@correo.com',
          'ticket': 'abc',
          'password': 'nueva1234',
        });
        return _json(200, {'ok': true, 'name': 'Manuel'});
      });
      final ticket = await service.verify('manuel@correo.com', '482193');
      expect(ticket, 'abc');
      expect(await service.finish('manuel@correo.com', ticket: ticket, password: 'nueva1234'), 'Manuel');
    });

    test('código incorrecto: dice cuántos intentos quedan', () async {
      final service = _service((_) async => _json(400, {'code': 'wrong-code', 'left': 2}));
      await expectLater(
        service.verify('manuel@correo.com', '111111'),
        throwsA(
          isA<RecoveryException>()
              .having((e) => e.error, 'error', RecoveryError.wrongCode)
              .having((e) => e.left, 'left', 2),
        ),
      );
    });

    test('cada respuesta de la función se traduce a su error', () {
      RecoveryError of(int status, [Map<String, dynamic> body = const {}]) =>
          RecoveryService.exceptionFor(status, body).error;
      expect(of(400, {'code': 'expired'}), RecoveryError.expired);
      expect(of(400, {'code': 'too-many-attempts'}), RecoveryError.tooManyAttempts);
      expect(of(400, {'code': 'weak-password'}), RecoveryError.weakPassword);
      expect(of(400, {'code': 'invalid-email'}), RecoveryError.invalidEmail);
      expect(of(500, {'code': 'server'}), RecoveryError.server);
      final throttled = RecoveryService.exceptionFor(429, {'code': 'throttled', 'retryAfter': 35});
      expect(throttled.error, RecoveryError.throttled);
      expect(throttled.retryAfter, 35);
    });

    test('sin la función (404) o sin correo configurado, no está disponible', () async {
      expect(RecoveryService.exceptionFor(404, const {}).error, RecoveryError.notAvailable);
      expect(
        RecoveryService.exceptionFor(503, {'code': 'mail-not-configured'}).error,
        RecoveryError.notAvailable,
      );
      // Una página de error que no es JSON también.
      final service = _service((_) async => http.Response('<html>Not Found</html>', 404));
      await expectLater(
        service.start('a@b.co', lang: 'es'),
        throwsA(isA<RecoveryException>().having((e) => e.error, 'error', RecoveryError.notAvailable)),
      );
      // Y sin URL de funciones.
      await expectLater(
        RecoveryService.at(null).start('a@b.co', lang: 'es'),
        throwsA(isA<RecoveryException>().having((e) => e.error, 'error', RecoveryError.notAvailable)),
      );
    });

    test('sin red es "sin conexión"', () async {
      final service = _service((_) async => throw http.ClientException('sin red'));
      await expectLater(
        service.start('a@b.co', lang: 'es'),
        throwsA(isA<RecoveryException>().having((e) => e.error, 'error', RecoveryError.offline)),
      );
    });

    test('la contraseña es la de antes si Firebase deja entrar con ella', () async {
      final same = _service((req) async {
        expect(req.url.host, 'identitytoolkit.googleapis.com');
        expect(req.url.queryParameters['key'], 'clave-publica');
        return _json(200, {'idToken': 'x'});
      });
      expect(
        await same.isCurrentPassword(email: 'a@b.co', password: 'vieja123', apiKey: 'clave-publica'),
        isTrue,
      );
      final other = _service((_) async => _json(400, {'error': {'message': 'INVALID_LOGIN_CREDENTIALS'}}));
      expect(await other.isCurrentPassword(email: 'a@b.co', password: 'x', apiKey: 'k'), isFalse);
      // Ante la duda (sin red o sin clave), no se bloquea a nadie.
      final offline = _service((_) async => throw http.ClientException('sin red'));
      expect(await offline.isCurrentPassword(email: 'a@b.co', password: 'x', apiKey: 'k'), isFalse);
      expect(await same.isCurrentPassword(email: 'a@b.co', password: 'x', apiKey: ''), isFalse);
    });

    test('los mensajes, en los dos idiomas', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      const wrong = RecoveryException(RecoveryError.wrongCode, left: 2);
      expect(wrong.message(es), 'Código incorrecto · te quedan 2 intentos');
      expect(const RecoveryException(RecoveryError.wrongCode, left: 1).message(es),
          'Código incorrecto · te queda 1 intento');
      expect(wrong.message(en), 'Wrong code · 2 tries left');
      for (final error in RecoveryError.values) {
        expect(RecoveryException(error).message(es), isNotEmpty);
        expect(RecoveryException(error).message(en), isNotEmpty);
      }
    });
  });

  test('fuerza de la contraseña: cuatro segmentos', () {
    expect(passwordStrength(''), 0);
    expect(passwordStrength('abcdefgh'), 1);
    expect(passwordStrength('abcdefg1'), 2);
    expect(passwordStrength('Abcdefg1'), 3);
    expect(passwordStrength('abcdefg1!'), 3);
    expect(passwordStrength('Abcdefghij12'), 4);
    expect(passwordAcceptable('abcdefg1'), isTrue);
    expect(passwordAcceptable('abcdefgh'), isFalse);
    expect(passwordAcceptable('abc1'), isFalse);
  });

  test('cuenta atrás de "Reenviar en"', () {
    expect(countdownLabel(42), '0:42');
    expect(countdownLabel(5), '0:05');
    expect(countdownLabel(75), '1:15');
    expect(countdownLabel(-3), '0:00');
  });

  testWidgets('las casillas: activa en énfasis, llenas en tinta, y todas rojas con error',
      (tester) async {
    const p = ViniloPalette.dark;
    BorderSide line(int i) {
      final box = tester.widget<Container>(find.byKey(ValueKey('code-cell-$i')));
      return ((box.decoration! as BoxDecoration).border! as Border).bottom;
    }

    await tester.pumpWidget(_app(const Scaffold(body: CodeCells(code: '4821'))));
    expect(find.text('4'), findsOneWidget);
    expect(line(0).color, p.ink);
    expect(line(0).width, 2);
    expect(line(4).color, p.accentText);
    expect(line(4).width, 2);
    expect(line(5).color, p.lineStrong);
    expect(line(5).width, 1);

    await tester.pumpWidget(_app(const Scaffold(body: CodeCells(code: '482193', error: true))));
    for (var i = 0; i < 6; i++) {
      expect(line(i).color, p.danger);
    }
    expect(tester.widget<Text>(find.text('9')).style?.color, p.danger);
  });

  testWidgets('el teclado manda cada dígito y borrar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pressed = <String>[];
    await tester.pumpWidget(
      _app(Scaffold(body: Align(alignment: Alignment.bottomCenter, child: NumberPad(onKey: pressed.add)))),
    );
    for (final key in ['4', '8', '0']) {
      await tester.tap(find.byKey(ValueKey('pad-$key')));
    }
    await tester.tap(find.byKey(const ValueKey('pad-delete')));
    expect(pressed, ['4', '8', '0', NumberPad.delete]);
    // Cada tecla mide 48 de alto: cabe un dedo.
    expect(tester.getSize(find.byKey(const ValueKey('pad-5'))).height, 48);
  });

  testWidgets('"Todo listo" saluda por el primer nombre', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const RecoverDoneScreen(name: 'Manuel Castillo')));
    expect(find.text('Todo listo, Manuel'), findsOneWidget);
    expect(find.text('ACTUALIZADA'), findsOneWidget);
    expect(find.text('Ir a Vinilo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_app(const RecoverDoneScreen(), locale: const Locale('en')));
    expect(find.text('All set'), findsOneWidget);
  });

  testWidgets('un campo con error pinta la etiqueta y el mensaje en rojo', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: LineField(
            label: 'Contraseña',
            error: 'La contraseña no coincide con ese usuario.',
            errorKey: ValueKey('auth-error'),
          ),
        ),
      ),
    );
    final label = tester.widget<Text>(
      find.descendant(of: find.byType(VMono), matching: find.text('CONTRASEÑA')),
    );
    expect(label.style?.color, ViniloPalette.dark.danger);
    final message = tester.widget<Text>(find.byKey(const ValueKey('auth-error')));
    expect(message.style?.color, ViniloPalette.dark.danger);
    expect(message.style?.fontSize, 13.5);
  });
}
