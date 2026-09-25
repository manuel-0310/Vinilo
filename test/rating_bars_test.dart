import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/rating_bars.dart';

void main() {
  group('RatingBarSpec (fórmulas de la especificación)', () {
    test('con el 7 elegido', () {
      final specs = [for (var k = 1; k <= 10; k++) RatingBarSpec.of(k, 7)];
      // d = 6 5 4 3 2 1 0 1 2 3
      expect(specs.map((s) => s.height), [30, 36, 56, 76, 96, 116, 136, 116, 96, 76]);
      expect(specs.map((s) => s.fontSize), [11, 11, 12, 15, 18, 21, 24, 21, 18, 15]);
      final opacities = specs.map((s) => s.opacity).toList();
      const expected = [0.16, 0.18, 0.29, 0.40, 0.51, 0.62, 1.0, 0.62, 0.51, 0.40];
      for (var i = 0; i < 10; i++) {
        expect(opacities[i], closeTo(expected[i], 1e-9), reason: 'columna ${i + 1}');
      }
      expect(specs.where((s) => s.selected).length, 1);
      expect(specs[6].selected, isTrue);
    });

    test('los mínimos: alto 30, número 11 y opacidad 0,16', () {
      final far = RatingBarSpec.of(1, 10);
      expect(far.height, 30);
      expect(far.fontSize, 11);
      expect(far.opacity, 0.16);
    });

    test('sin nota elegida, todas en su mínimo', () {
      for (var k = 1; k <= 10; k++) {
        final s = RatingBarSpec.of(k, null);
        expect(s.height, 30);
        expect(s.fontSize, 11);
        expect(s.opacity, 0.16);
        expect(s.selected, isFalse);
      }
    });
  });

  testWidgets('tocar una columna elige esa nota', (tester) async {
    int? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildViniloTheme(ViniloPalette.dark),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: StatefulBuilder(
                builder: (context, setState) => RatingBars(
                  value: picked,
                  onChanged: (k) => setState(() => picked = k),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dial-8')));
    await tester.pumpAndSettle();
    expect(picked, 8);

    // Deslizar hacia la izquierda baja la nota.
    final bars = tester.getRect(find.byType(RatingBars));
    await tester.dragFrom(Offset(bars.left + bars.width * 0.75, bars.center.dy), Offset(-bars.width * 0.5, 0));
    await tester.pumpAndSettle();
    expect(picked, lessThan(8));
  });
}
