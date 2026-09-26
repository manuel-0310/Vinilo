import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/theme/oklch.dart';

/// Diferencia máxima entre los canales de dos colores, en pasos de 0 a 255.
double channelDiff(Color a, Color b) => [
      (a.r - b.r).abs(),
      (a.g - b.g).abs(),
      (a.b - b.b).abs(),
    ].reduce((x, y) => x > y ? x : y) * 255;

void main() {
  test('el bermellón del prototipo es #FD6A3A', () {
    final color = const Oklch(0.7, 0.19, 38).toColor();
    expect(channelDiff(color, const Color(0xFFFD6A3A)), lessThanOrEqualTo(1));
  });

  test('ida y vuelta: sRGB → OKLCH → sRGB', () {
    for (final value in [0xFFFD6A3A, 0xFF2FB5D8, 0xFF0F0E0D, 0xFFEFEBE4, 0xFF777777, 0xFFAC713E]) {
      final color = Color(value);
      final back = Oklch.fromColor(color).toColor();
      expect(channelDiff(color, back), lessThanOrEqualTo(1), reason: color.toString());
    }
  });

  test('blanco, negro y gris', () {
    final white = Oklch.fromColor(const Color(0xFFFFFFFF));
    expect(white.l, closeTo(1, 0.001));
    expect(white.c, closeTo(0, 0.001));
    expect(Oklch.fromColor(const Color(0xFF000000)).l, closeTo(0, 0.001));
    expect(Oklch.fromColor(const Color(0xFF808080)).c, closeTo(0, 0.001));
  });

  test('fuera de la gama baja el croma y conserva luminosidad y tonalidad', () {
    const wild = Oklch(0.7, 0.4, 150);
    final color = wild.toColor();
    final back = Oklch.fromColor(color);
    expect(back.l, closeTo(0.7, 0.01));
    expect((back.h - 150).abs(), lessThan(3));
    expect(back.c, lessThan(0.4));
    for (final ch in [color.r, color.g, color.b]) {
      expect(ch, inInclusiveRange(0, 1));
    }
  });

  test('la opacidad se respeta', () {
    expect(const Oklch(0.5, 0.1, 20).toColor(opacity: 0.35).a, closeTo(0.35, 0.001));
  });

  test('distancia: cero entre iguales y mayor entre colores lejanos', () {
    const a = Color(0xFFFD6A3A);
    expect(Oklch.distance(a, a), 0);
    expect(Oklch.distance(a, const Color(0xFFF66B71)), lessThan(Oklch.distance(a, const Color(0xFF2FB5D8))));
  });
}
