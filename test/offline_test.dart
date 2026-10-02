import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/outbox.dart';
import 'package:no_retiene/services/connectivity_service.dart';
import 'package:no_retiene/services/outbox_sync.dart';
import 'package:no_retiene/services/spotify_api.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/util/errors.dart';
import 'package:no_retiene/util/search_text.dart';
import 'package:no_retiene/widgets/v_states.dart';

const _album = Album(
  id: '2Xy3Sr5Rd8Hx4Tb5Dz8XXX',
  name: 'Bocanada',
  artist: 'Gustavo Cerati',
  artistIds: ['1'],
  artistNames: ['Gustavo Cerati'],
  year: 1999,
);

Widget _app(Widget home) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Una conexión que se cambia a mano: la sonda responde lo que diga `up`.
class _Net {
  bool up = true;
  ConnectivityService service() =>
      ConnectivityService(probe: () async => up, retryEvery: const Duration(hours: 1));
}

void main() {
  group('errores', () {
    test('sin conexión: Spotify sin red o lento, Firestore no disponible', () {
      expect(isOfflineError(SpotifyApiException(SpotifyError.offline)), isTrue);
      expect(isOfflineError(SpotifyApiException(SpotifyError.timeout)), isTrue);
      expect(isOfflineError(TimeoutException('lento')), isTrue);
      expect(isOfflineError(http.ClientException('sin red')), isTrue);
      expect(isOfflineError(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')), isTrue);
      expect(isOfflineError(FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded')), isTrue);
    });

    test('un permiso negado o un error del servidor no son falta de conexión', () {
      expect(isOfflineError(null), isFalse);
      expect(isOfflineError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')), isFalse);
      expect(isOfflineError(SpotifyApiException(SpotifyError.server, status: 502)), isFalse);
      expect(isOfflineError(StateError('otra cosa')), isFalse);
    });

    test('error del servidor: Spotify 5xx o Firestore interno; un 404 no', () {
      expect(isServerError(SpotifyApiException(SpotifyError.server, status: 500)), isTrue);
      expect(isServerError(SpotifyApiException(SpotifyError.server, status: 503)), isTrue);
      expect(isServerError(SpotifyApiException(SpotifyError.server, status: 404)), isFalse);
      expect(isServerError(FirebaseException(plugin: 'cloud_firestore', code: 'internal')), isTrue);
      expect(isServerError(SpotifyApiException(SpotifyError.offline)), isFalse);
    });

    test('el código lleva el estado y cuatro cifras hexadecimales', () {
      final code = errorCode(SpotifyApiException(SpotifyError.server, status: 503), math.Random(1));
      expect(code, matches(RegExp(r'^VN-503-[0-9A-F]{4}$')));
      expect(errorCode(StateError('x'), math.Random(2)), startsWith('VN-500-'));
      expect(serverStatusOf(null), 500);
    });
  });

  group('cola de notas', () {
    test('ida y vuelta del documento de la cola', () {
      final pending = PendingRating(
        album: _album,
        score: 9,
        note: 'Un viaje',
        createdAt: DateTime(2026, 10, 2, 12),
      );
      final map = pending.toMap();
      expect(map['score'], 9);
      expect(map['note'], 'Un viaje');
      expect(map['createdAt'], isA<Timestamp>());
      final back = PendingRating.fromMap(map);
      expect(back.albumId, _album.id);
      expect(back.album.name, 'Bocanada');
      expect(back.score, 9);
      expect(back.note, 'Un viaje');
      expect(back.createdAt, DateTime(2026, 10, 2, 12));
      expect(back.isValid, isTrue);
    });

    test('una nota fuera de 1–10 o sin disco no se sube', () {
      expect(PendingRating(album: _album, score: 0, note: '', createdAt: DateTime(2026)).isValid, isFalse);
      expect(PendingRating(album: _album, score: 11, note: '', createdAt: DateTime(2026)).isValid, isFalse);
      expect(PendingRating.fromMap(const {'score': 7}).isValid, isFalse);
    });
  });

  group('conexión', () {
    test('una falla se comprueba y, si de verdad no hay red, avisa', () async {
      final net = _Net()..up = false;
      final connectivity = net.service();
      addTearDown(connectivity.dispose);
      var changes = 0;
      connectivity.addListener(() => changes++);
      expect(connectivity.online, isTrue);
      connectivity.reportFailure();
      await connectivity.check();
      expect(connectivity.offline, isTrue);
      expect(changes, greaterThan(0));
      net.up = true;
      expect(await connectivity.check(), isTrue);
      expect(connectivity.online, isTrue);
    });

    test('reportSuccess vuelve a "con conexión" sin comprobar', () async {
      final net = _Net()..up = false;
      final connectivity = net.service();
      addTearDown(connectivity.dispose);
      await connectivity.check();
      expect(connectivity.offline, isTrue);
      connectivity.reportSuccess();
      expect(connectivity.online, isTrue);
    });
  });

  group('subir la cola', () {
    test('sube cuando hay algo y hay conexión', () async {
      final net = _Net();
      final connectivity = net.service();
      final counts = StreamController<int>();
      var flushes = 0;
      final sync = OutboxSync(
        connectivity: connectivity,
        pendingCount: counts.stream,
        flush: () async {
          flushes++;
          return 1;
        },
      )..start();
      addTearDown(() {
        sync.dispose();
        connectivity.dispose();
        counts.close();
      });
      counts.add(0);
      await pumpEventQueue();
      expect(flushes, 0);
      counts.add(2);
      await pumpEventQueue();
      expect(flushes, 1);
    });

    test('sin conexión espera y sube cuando vuelve', () async {
      final net = _Net()..up = false;
      final connectivity = net.service();
      await connectivity.check();
      final counts = StreamController<int>();
      var flushes = 0;
      final sync = OutboxSync(
        connectivity: connectivity,
        pendingCount: counts.stream,
        flush: () async {
          flushes++;
          return 1;
        },
      )..start();
      addTearDown(() {
        sync.dispose();
        connectivity.dispose();
        counts.close();
      });
      counts.add(1);
      await pumpEventQueue();
      expect(flushes, 0);
      net.up = true;
      await connectivity.check();
      await pumpEventQueue();
      expect(flushes, 1);
    });

    test('si se corta a mitad de subida, avisa y no insiste en el acto', () async {
      final net = _Net();
      final connectivity = net.service();
      final counts = StreamController<int>();
      var flushes = 0;
      final sync = OutboxSync(
        connectivity: connectivity,
        pendingCount: counts.stream,
        retryAfter: const Duration(hours: 1),
        flush: () async {
          flushes++;
          net.up = false;
          throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
        },
      )..start();
      addTearDown(() {
        sync.dispose();
        connectivity.dispose();
        counts.close();
      });
      counts.add(1);
      await pumpEventQueue();
      expect(flushes, 1);
      expect(connectivity.offline, isTrue);
      counts.add(1);
      await pumpEventQueue();
      expect(flushes, 1);
    });

    test('lo que llega a la cola mientras sube se sube en otra vuelta', () async {
      final net = _Net();
      final connectivity = net.service();
      final counts = StreamController<int>();
      final gate = Completer<void>();
      var flushes = 0;
      final sync = OutboxSync(
        connectivity: connectivity,
        pendingCount: counts.stream,
        flush: () async {
          flushes++;
          if (flushes == 1) await gate.future;
          return 1;
        },
      )..start();
      addTearDown(() {
        sync.dispose();
        connectivity.dispose();
        counts.close();
      });
      counts.add(1);
      await pumpEventQueue();
      counts.add(2);
      await pumpEventQueue();
      expect(flushes, 1);
      gate.complete();
      await pumpEventQueue();
      expect(flushes, 2);
    });
  });

  group('¿Quisiste decir?', () {
    test('sin letras repetidas y cada palabra larga sola', () {
      expect(didYouMeanQueries('ceratti bocanda'), ['cerati bocanda', 'cerati', 'bocanda']);
    });

    test('una palabra: solo la versión sin repetidas, si cambia', () {
      expect(didYouMeanQueries('Raddiohead'), ['radiohead']);
      expect(didYouMeanQueries('radiohead'), isEmpty);
    });

    test('nunca la original, nada para @usuario y un tope', () {
      expect(didYouMeanQueries('@manuel'), isEmpty);
      expect(didYouMeanQueries(''), isEmpty);
      expect(didYouMeanQueries('soda stereo signos'), isNot(contains('soda stereo signos')));
      expect(didYouMeanQueries('el mal querer motomami'), ['motomami', 'querer']);
      expect(didYouMeanQueries('ceratti bocanda', max: 2), hasLength(2));
    });
  });

  group('pantallas de estado', () {
    testWidgets('"Sin conexión" con Reintentar y los discos guardados', (tester) async {
      _phone(tester);
      var retried = 0;
      var saved = 0;
      await tester.pumpWidget(_app(Scaffold(
        body: OfflineState(onRetry: () => retried++, onSaved: () => saved++),
      )));
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('SIN SEÑAL'), findsOneWidget);
      expect(find.text('LADO B'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('offline-retry')));
      await tester.tap(find.byKey(const ValueKey('offline-saved')));
      expect(retried, 1);
      expect(saved, 1);
    });

    testWidgets('mientras comprueba dice "Conectando…" y no se puede tocar', (tester) async {
      _phone(tester);
      var retried = 0;
      await tester.pumpWidget(_app(Scaffold(
        body: OfflineState(onRetry: () => retried++, checking: true),
      )));
      expect(find.text('Conectando…'), findsOneWidget);
      expect(find.byKey(const ValueKey('offline-saved')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('offline-retry')));
      expect(retried, 0);
    });

    testWidgets('"Se rayó el disco" con el estado y un código estable', (tester) async {
      _phone(tester);
      final error = SpotifyApiException(SpotifyError.server, status: 503);
      await tester.pumpWidget(_app(Scaffold(
        body: ServerErrorState(error: error, onRetry: () {}),
      )));
      expect(find.text('503'), findsOneWidget);
      expect(find.text('Se rayó el disco'), findsOneWidget);
      final code = tester.widget<Text>(
        find.descendant(of: find.byKey(const ValueKey('server-error-code')), matching: find.byType(Text)),
      );
      expect(code.data, matches(RegExp(r'^CÓDIGO · VN-503-[0-9A-F]{4}$')));
      await tester.pumpWidget(_app(Scaffold(
        body: ServerErrorState(error: error, onRetry: () {}, retrying: true),
      )));
      final again = tester.widget<Text>(
        find.descendant(of: find.byKey(const ValueKey('server-error-code')), matching: find.byType(Text)),
      );
      expect(again.data, code.data);
    });

    testWidgets('el aviso del inicio llama a Reintentar', (tester) async {
      _phone(tester);
      var retried = 0;
      await tester.pumpWidget(_app(Scaffold(body: OfflineBanner(onRetry: () => retried++))));
      expect(find.text('Sin conexión · mostrando lo último guardado'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('offline-banner')));
      expect(retried, 1);
    });
  });
}
