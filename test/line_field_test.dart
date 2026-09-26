import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/line_field.dart';

Widget _app(Widget child) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: child)),
    );

/// Los bordes que el `TextField` de dentro pintaría en cada estado.
List<InputBorder?> _borders(InputDecoration d) => [
      d.border,
      d.enabledBorder,
      d.focusedBorder,
      d.disabledBorder,
      d.errorBorder,
      d.focusedErrorBorder,
    ];

/// Las líneas de abajo que dibujan los `Container` del campo.
List<BorderSide> _bottomLines(WidgetTester tester) => tester
    .widgetList<Container>(find.descendant(of: find.byType(LineField), matching: find.byType(Container)))
    .map((w) => w.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.border)
    .whereType<Border>()
    .map((b) => b.bottom)
    .where((s) => s.style != BorderStyle.none && s.width > 0)
    .toList();

void main() {
  testWidgets('LineField: el TextField no pinta raya propia, solo queda la del campo', (tester) async {
    await tester.pumpWidget(_app(const LineField(label: 'correo', hint: 'tu@correo.com', fieldKey: ValueKey('f'))));

    final decoration = tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
    expect(_borders(decoration), everyElement(InputBorder.none));
    expect(_bottomLines(tester), hasLength(1));

    // Con foco sigue habiendo una sola raya, ahora de 2 px.
    await tester.tap(find.byKey(const ValueKey('f')));
    await tester.pump();
    final focused = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(focused.isFocused, isTrue);
    expect(_borders(focused.decoration), everyElement(InputBorder.none));
    final lines = _bottomLines(tester);
    expect(lines, hasLength(1));
    expect(lines.single.width, 2);
  });

  testWidgets('el tema no le da raya a ningún campo', (tester) async {
    await tester.pumpWidget(_app(const TextField()));
    final decoration = tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
    expect(_borders(decoration), everyElement(InputBorder.none));
  });
}
