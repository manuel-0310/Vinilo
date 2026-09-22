import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/theme/score.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

void main() {
  group('accentFor', () {
    test('el ámbar por defecto conserva su carácter en ambos temas', () {
      final dark = accentFor(ViniloPalette.defaultSeed, Brightness.dark);
      final light = accentFor(ViniloPalette.defaultSeed, Brightness.light);
      expect(HSLColor.fromColor(dark).lightness, closeTo(0.60, 0.03));
      expect(HSLColor.fromColor(light).lightness, closeTo(0.41, 0.06));
    });

    test('todo color elegible se aclara en oscuro y se oscurece en claro', () {
      for (final seed in VColors.accentPalette) {
        final dark = HSLColor.fromColor(accentFor(seed, Brightness.dark));
        final light = HSLColor.fromColor(accentFor(seed, Brightness.light));
        expect(dark.lightness, inInclusiveRange(0.57, 0.73), reason: '$seed');
        expect(light.lightness, inInclusiveRange(0.33, 0.45), reason: '$seed');
      }
    });
  });

  test('el texto sobre el énfasis contrasta al menos 3:1 en ambos temas', () {
    for (final seed in VColors.accentPalette) {
      for (final b in Brightness.values) {
        final accent = accentFor(seed, b);
        final on = onAccentFor(accent);
        expect(contrastRatio(accent, on), greaterThanOrEqualTo(3.0),
            reason: '$seed en $b');
      }
    }
  });

  group('Score.color', () {
    test('a mayor nota, más saturación (más intensidad)', () {
      for (final seed in VColors.accentPalette) {
        for (final light in [false, true]) {
          final accent = accentFor(seed, light ? Brightness.light : Brightness.dark);
          var previous = -1.0;
          for (var n = 1; n <= 10; n++) {
            final s = HSLColor.fromColor(Score.color(n, accent: accent, light: light))
                .saturation;
            expect(s, greaterThan(previous), reason: '$seed nota $n light=$light');
            previous = s;
          }
        }
      }
    });

    test('las notas se leen sobre el fondo de su tema', () {
      for (final seed in VColors.accentPalette) {
        for (var n = 1; n <= 10; n++) {
          final dark = Score.color(n, accent: accentFor(seed, Brightness.dark));
          final light = Score.color(n,
              accent: accentFor(seed, Brightness.light), light: true);
          expect(contrastRatio(dark, ViniloPalette.dark.bg), greaterThan(2.5),
              reason: '$seed nota $n oscuro');
          expect(contrastRatio(light, ViniloPalette.light.bg), greaterThan(2.3),
              reason: '$seed nota $n claro');
        }
      }
    });

    test('acepta promedios con decimales y los acota', () {
      final accent = accentFor(ViniloPalette.defaultSeed, Brightness.dark);
      expect(Score.color(0, accent: accent), Score.color(1, accent: accent));
      expect(Score.color(11, accent: accent), Score.color(10, accent: accent));
      expect(Score.color(7.5, accent: accent), isNot(Score.color(7, accent: accent)));
    });
  });

  test('withSeed deriva accent y onAccent del color elegido', () {
    final p = ViniloPalette.dark.withSeed(const Color(0xFF5FA8D3));
    expect(p.seed, const Color(0xFF5FA8D3));
    expect(p.accent, accentFor(const Color(0xFF5FA8D3), Brightness.dark));
    expect(p.onAccent, onAccentFor(p.accent));
  });
}
