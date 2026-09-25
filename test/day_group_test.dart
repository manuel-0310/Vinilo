import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/util/format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
  });
  final now = DateTime(2026, 9, 25, 9);
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('hoy y ayer se cuentan por días del calendario', () {
    expect(dayGroup(DateTime(2026, 9, 25, 0, 5), es, now: now), 'Hoy');
    expect(dayGroup(DateTime(2026, 9, 24, 23, 50), es, now: now), 'Ayer');
    expect(dayGroup(DateTime(2026, 9, 24, 1), en, now: now), 'Yesterday');
    expect(dayGroup(DateTime(2026, 9, 25, 8), en, now: now), 'Today');
  });

  test('esta semana: hasta 6 días atrás', () {
    expect(dayGroup(DateTime(2026, 9, 23), es, now: now), 'Esta semana');
    expect(dayGroup(DateTime(2026, 9, 19, 22), en, now: now), 'This week');
  });

  test('antes, el mes y el año', () {
    expect(dayGroup(DateTime(2026, 9, 18), es, now: now), 'Septiembre 2026');
    expect(dayGroup(DateTime(2026, 8, 2), en, now: now), 'August 2026');
    expect(dayGroup(DateTime(2025, 12, 31), es, now: now), 'Diciembre 2025');
  });
}
