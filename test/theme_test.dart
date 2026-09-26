import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/theme/oklch.dart';
import 'package:no_retiene/theme/score.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';

/// Diferencia de tonalidad en grados, dando la vuelta al círculo.
double hueDiff(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  // Los colores de énfasis tal como los escribe el prototipo.
  const prototype = [
    Oklch(0.7, 0.19, 38),
    Oklch(0.7, 0.17, 20),
    Oklch(0.78, 0.15, 85),
    Oklch(0.78, 0.16, 125),
    Oklch(0.72, 0.15, 150),
    Oklch(0.72, 0.12, 180),
    Oklch(0.72, 0.12, 220),
    Oklch(0.65, 0.15, 255),
    Oklch(0.65, 0.15, 285),
    Oklch(0.7, 0.15, 310),
    Oklch(0.7, 0.16, 340),
    Oklch(0.64, 0.19, 5),
    Oklch(0.6, 0.1, 60),
  ];

  // La paleta de antes del rediseño (lo que pueden tener guardado).
  const before = [
    0xFFE8A04B, 0xFFD26A5C, 0xFF8DBB7A, 0xFF5FA8D3, 0xFFB08CF0, 0xFFE07BB0, 0xFF4FC3B0,
    0xFFF2D06B, 0xFF5B7FE8, 0xFFE0546E, 0xFF3FAE7A, 0xFFF08A3C, 0xFFB5CF5A, 0xFFC45BD6,
  ];

  test('la paleta es la del prototipo convertida de OKLCH, más la tinta', () {
    expect(VColors.accentPalette, hasLength(14));
    for (var i = 0; i < prototype.length; i++) {
      final expected = prototype[i].toColor();
      final actual = VColors.accentPalette[i];
      for (final (e, a) in [(expected.r, actual.r), (expected.g, actual.g), (expected.b, actual.b)]) {
        expect((e * 255 - a * 255).abs(), lessThanOrEqualTo(1), reason: '${prototype[i]}');
      }
    }
    expect(VColors.accentPalette.last, const Color(0xFFEFEBE4));
    expect(ViniloPalette.defaultAccent, VColors.accentPalette.first);
  });

  test('el texto sobre cualquier énfasis se lee (3:1 o más)', () {
    for (final accent in VColors.accentPalette) {
      expect(contrastRatio(accent, ViniloPalette.dark.onAccent), greaterThanOrEqualTo(3.0),
          reason: '$accent');
    }
  });

  group('VColors.nearest', () {
    test('un color de la paleta se queda igual', () {
      for (final accent in VColors.accentPalette) {
        expect(VColors.nearest(accent), accent);
      }
    });

    test('los colores de antes caen en uno de la paleta nueva de la misma familia', () {
      for (final value in before) {
        final old = Color(value);
        final now = VColors.nearest(old);
        expect(VColors.accentPalette, contains(now));
        final a = Oklch.fromColor(old);
        final b = Oklch.fromColor(now);
        expect(hueDiff(a.h, b.h), lessThan(20), reason: '$old → $now');
      }
    });
  });

  group('tonos derivados', () {
    test('coverTone mantiene la tonalidad y sube la luminosidad a 0,76', () {
      final cover = const Oklch(0.42, 0.14, 255).toColor();
      final tone = Oklch.fromColor(coverTone(cover));
      expect(tone.l, closeTo(0.76, 0.01));
      expect(hueDiff(tone.h, 255), lessThan(3));
      expect(tone.c, inInclusiveRange(0.1, 0.15));
    });

    test('una portada clara se queda clara', () {
      final tone = Oklch.fromColor(coverTone(const Oklch(0.88, 0.03, 220).toColor()));
      expect(tone.l, inInclusiveRange(0.84, 0.87));
    });

    test('una portada gris da un tono gris', () {
      final tone = Oklch.fromColor(coverTone(const Color(0xFF777777)));
      expect(tone.c, lessThan(0.02));
      expect(tone.l, closeTo(0.76, 0.01));
    });

    test('coverShade oscurece (franja de las listas y banner)', () {
      final shade = Oklch.fromColor(coverShade(const Oklch(0.5, 0.12, 50).toColor()));
      expect(shade.l, closeTo(0.31, 0.01));
      expect(shade.c, lessThanOrEqualTo(0.081));
      final banner = Oklch.fromColor(coverShade(VColors.accentPalette.first, lightness: 0.35));
      expect(banner.l, closeTo(0.35, 0.01));
    });

    test('personTone apaga el color de la persona', () {
      for (final accent in VColors.accentPalette) {
        final tone = Oklch.fromColor(personTone(accent));
        expect(tone.l, closeTo(0.44, 0.01));
        expect(tone.c, lessThanOrEqualTo(0.121));
      }
    });
  });

  group('modo claro', () {
    const light = ViniloPalette.light;

    test('los tokens son los de la especificación', () {
      expect(light.brightness, Brightness.light);
      expect(light.bg, const Color(0xFFF3EFE7));
      expect(light.sheet, const Color(0xFFFBF9F5));
      expect(light.surface, const Color(0xFFE2DDD3));
      expect(light.ink, const Color(0xFF161412));
      expect(light.ink2.a, closeTo(0.68, 0.005));
      expect(light.ink3.a, closeTo(0.62, 0.005));
      expect(light.ink4.a, closeTo(0.55, 0.005));
      expect(light.line.a, closeTo(0.14, 0.005));
      expect(light.lineSoft.a, closeTo(0.08, 0.005));
      expect(light.lineStrong.a, closeTo(0.30, 0.005));
      expect(light.scrim.a, closeTo(0.40, 0.005));
      expect(light.onAccent, const Color(0xFF0F0E0D));
    });

    test('accentText baja a luminosidad 0,52 con la misma tonalidad', () {
      for (final accent in VColors.accentPalette.take(13)) {
        final p = light.withAccent(accent);
        expect(p.accent, accent);
        final o = Oklch.fromColor(p.accentText);
        expect(o.l, closeTo(0.52, 0.01));
        expect(o.h, closeTo(Oklch.fromColor(accent).h, 3));
      }
    });

    test('el énfasis como texto se lee sobre el papel (3:1 o más)', () {
      for (final accent in VColors.accentPalette) {
        final p = light.withAccent(accent);
        expect(contrastRatio(p.accentText, p.bg), greaterThanOrEqualTo(3), reason: '$accent');
        expect(contrastRatio(p.onAccent, p.accent), greaterThanOrEqualTo(3), reason: '$accent');
      }
    });

    test('la opción de tinta pasa a ser la tinta oscura con papel encima', () {
      final p = light.withAccent(VColors.inkAccent);
      expect(p.accent, light.ink);
      expect(p.accentText, light.ink);
      expect(p.onAccent, light.bg);
      expect(p.swatch(VColors.inkAccent), light.ink);
      expect(ViniloPalette.dark.swatch(VColors.inkAccent), VColors.inkAccent);
    });

    test('los tonos de portada se oscurecen y los fondos se aclaran', () {
      const cover = Color(0xFF3A6EA5);
      expect(Oklch.fromColor(light.coverTone(cover)).l, closeTo(0.48, 0.05));
      expect(contrastRatio(light.coverTone(cover), light.bg), greaterThanOrEqualTo(3));
      expect(Oklch.fromColor(light.coverShade(cover)).l, closeTo(0.86, 0.01));
      expect(Oklch.fromColor(light.coverShade(cover, lightness: 0.35)).l, closeTo(0.82, 0.01));
      expect(contrastRatio(light.ink, light.personTone(cover)), greaterThanOrEqualTo(4.5));
      // En oscuro no cambia nada.
      expect(ViniloPalette.dark.coverTone(cover), coverTone(cover));
    });

    test('el tema claro se arma con brillo claro', () {
      final theme = buildViniloTheme(light.withAccent(VColors.accentPalette[3]));
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, light.bg);
    });
  });

  test('withAccent cambia solo el énfasis', () {
    final p = ViniloPalette.dark.withAccent(VColors.accentPalette[7]);
    expect(p.accent, VColors.accentPalette[7]);
    expect(p.accentText, VColors.accentPalette[7]);
    expect(p.bg, ViniloPalette.dark.bg);
    expect(p.onAccent, const Color(0xFF0F0E0D));
  });

  test('los promedios llevan coma en español y punto en inglés', () {
    expect(Score.formatAverage(9.5), '9,5');
    expect(Score.formatAverage(9.5, 'en'), '9.5');
    expect(Score.formatAverage(8), '8,0');
  });
}
