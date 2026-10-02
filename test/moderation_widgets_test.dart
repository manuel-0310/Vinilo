import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/moderation.dart';
import 'package:no_retiene/screens/moderation_actions.dart';
import 'package:no_retiene/screens/report_screen.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/menu_sheet.dart';
import 'package:no_retiene/widgets/v_buttons.dart';
import 'package:no_retiene/widgets/v_choices.dart';

Widget _app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

const _santi = PersonInfo(
  uid: 'santi',
  name: 'Santiago Mejía',
  colorValue: 0xFF8C352A,
  username: 'santi',
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('el menú devuelve la opción tocada y "Cancelar" no devuelve nada', (tester) async {
    _phone(tester);
    Object? result = 'sin tocar';
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showMenuSheet<String>(
                  context,
                  overline: '@santi',
                  items: const [
                    MenuSheetItem(value: 'share', label: 'Compartir perfil', keyName: 'menu-share'),
                    MenuSheetItem(
                      value: 'mute',
                      label: 'Silenciar',
                      hint: 'No verás su actividad',
                      keyName: 'menu-mute',
                    ),
                    MenuSheetItem(
                      value: 'block',
                      label: 'Bloquear a @santi',
                      danger: true,
                      strong: true,
                      keyName: 'menu-block',
                    ),
                  ],
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('@SANTI'), findsOneWidget);
    expect(find.text('NO VERÁS SU ACTIVIDAD'), findsOneWidget);
    // La opción que bloquea va en el color de peligro.
    final block = tester.widget<Text>(find.text('Bloquear a @santi'));
    expect(block.style?.color, ViniloPalette.dark.danger);

    await tester.tap(find.byKey(const ValueKey('menu-mute')));
    await tester.pumpAndSettle();
    expect(result, 'mute');

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('la hoja de bloqueo explica las cuatro reglas y se puede cancelar', (tester) async {
    _phone(tester);
    bool? result;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await confirmBlock(context, _santi),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Bloquear a @santi?'), findsOneWidget);
    for (final n in ['01', '02', '03', '04']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('Sus calificaciones y comentarios desaparecen de tu inicio.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('block-cancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('reportar: no se puede enviar hasta elegir un motivo', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const ReportScreen(
          type: ReportTarget.rating,
          targetId: 'tomas_a1',
          target: PersonInfo(uid: 'tomas', name: 'Tomás G.', colorValue: 0xFF000000, username: 'tomasg'),
          ratingId: 'tomas_a1',
        ),
      ),
    );
    expect(find.text('REPORTAR COMENTARIO DE @TOMASG'), findsOneWidget);
    expect(find.text('¿Qué está pasando?'), findsOneWidget);
    expect(find.text('Tu reporte es anónimo. @tomasg no sabrá que fuiste tú.'), findsOneWidget);
    // Los siete motivos, en el orden del prototipo.
    for (final title in [
      'Spam',
      'Acoso o bullying',
      'Discurso de odio',
      'Contenido sexual',
      'Suplantación',
      'Violencia o amenazas',
      'Otro',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    VPrimaryButton send() => tester.widget<VPrimaryButton>(find.byKey(const ValueKey('report-send')));
    expect(send().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('report-reason-harassment')));
    await tester.pumpAndSettle();
    expect(send().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reportar a una persona dice a quién, también en inglés', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const ReportScreen(type: ReportTarget.user, targetId: 'santi', target: _santi),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('REPORT @SANTI'), findsOneWidget);
    expect(find.text("What's going on?"), findsOneWidget);
    expect(find.text('Send report'), findsOneWidget);
  });

  testWidgets('el interruptor avisa el valor contrario al tocarlo', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Center(
              child: VSwitch(value: value, onChanged: (v) => setState(() => value = v)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(VSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.tap(find.byType(VSwitch));
    await tester.pumpAndSettle();
    expect(value, isFalse);
    // El toque mide 44 de alto aunque el interruptor mida 28.
    expect(tester.getSize(find.byType(VSwitch)).height, 44);
  });

  test('a quien no tiene @usuario se le nombra por su nombre', () {
    expect(handleOf(_santi), '@santi');
    expect(
      handleOf(const PersonInfo(uid: 'x', name: 'Valeria R.', colorValue: 0xFF000000)),
      'Valeria R.',
    );
  });
}
