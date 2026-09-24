import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/theme/score.dart';
import 'package:no_retiene/util/format.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Los marcadores declarados en la plantilla (`@clave.placeholders`).
Set<String> _declared(Map<String, dynamic> arb, String key) =>
    ((arb['@$key'] as Map<String, dynamic>?)?['placeholders'] as Map<String, dynamic>?)
        ?.keys
        .toSet() ??
    const {};

bool _uses(String text, String placeholder) =>
    text.contains('{$placeholder}') || text.contains('{$placeholder,');

void main() {
  final es = _arb('es');
  final en = _arb('en');

  test('español e inglés tienen exactamente las mismas claves', () {
    expect(_keys(en).difference(_keys(es)), isEmpty, reason: 'sobran en inglés');
    expect(_keys(es).difference(_keys(en)), isEmpty, reason: 'faltan en inglés');
  });

  test('cada texto usa sus marcadores en los dos idiomas', () {
    for (final key in _keys(es)) {
      for (final ph in _declared(es, key)) {
        expect(_uses(es[key] as String, ph), isTrue, reason: '$key (es) sin {$ph}');
        expect(_uses(en[key] as String, ph), isTrue, reason: '$key (en) sin {$ph}');
      }
    }
  });

  test('ningún texto está vacío', () {
    for (final arb in [es, en]) {
      for (final key in _keys(arb)) {
        expect((arb[key] as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  group('timeAgo', () {
    setUpAll(() async {
      await initializeDateFormatting('es');
      await initializeDateFormatting('en');
    });
    final now = DateTime(2026, 9, 23, 12);
    final l10nEs = lookupAppLocalizations(const Locale('es'));
    final l10nEn = lookupAppLocalizations(const Locale('en'));

    test('habla el idioma de la app', () {
      final fiveMin = now.subtract(const Duration(minutes: 5));
      expect(timeAgo(fiveMin, l10nEs, now: now), 'hace 5 min');
      expect(timeAgo(fiveMin, l10nEn, now: now), '5 min ago');
      final yesterday = now.subtract(const Duration(days: 1));
      expect(timeAgo(yesterday, l10nEs, now: now), 'ayer');
      expect(timeAgo(yesterday, l10nEn, now: now), 'yesterday');
      final threeDays = now.subtract(const Duration(days: 3));
      expect(timeAgo(threeDays, l10nEs, now: now), 'hace 3 días');
      expect(timeAgo(threeDays, l10nEn, now: now), '3 days ago');
    });

    test('más de una semana muestra la fecha con el mes del idioma', () {
      final date = DateTime(2026, 8, 12);
      expect(timeAgo(date, l10nEn, now: now), '12 Aug');
      // En español, agosto abreviado es "ago".
      expect(timeAgo(date, l10nEs, now: now), '12 ago');
    });
  });

  test('el promedio usa coma en español y punto en inglés', () {
    expect(Score.formatAverage(8.44, 'es'), '8,4');
    expect(Score.formatAverage(8.44, 'en'), '8.4');
  });
}
