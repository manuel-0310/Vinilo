import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/v_ruler.dart';

Widget _app(Widget child) => MaterialApp(
      theme: buildViniloTheme(ViniloPalette.dark),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('RulerCells sin onTap solo muestra: tocarla no hace nada', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(_app(const RulerCells(selected: 7, fill: Color(0xFF1B3A6B))));
    await tester.tap(find.byKey(const ValueKey('ruler-3')));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method.startsWith('HapticFeedback')), isEmpty);
    final detector = tester.widget<GestureDetector>(find.byKey(const ValueKey('ruler-3')));
    expect(detector.onTap, isNull);
  });

  testWidgets('RulerCells con onTap avisa la celda tocada (el filtro del diario)', (tester) async {
    int? tapped;
    await tester.pumpWidget(_app(RulerCells(selected: 7, onTap: (k) => tapped = k)));
    await tester.tap(find.byKey(const ValueKey('ruler-3')));
    expect(tapped, 3);
  });
}
