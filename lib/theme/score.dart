import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Todo lo relacionado con la nota del 1 al 10: etiquetas, color y formato.
class Score {
  Score._();

  static const int min = 1;
  static const int max = 10;

  /// "Obra maestra" / "Masterpiece"… en el idioma de la app.
  static String label(int score, AppLocalizations l) => switch (score) {
        1 => l.score1,
        2 => l.score2,
        3 => l.score3,
        4 => l.score4,
        5 => l.score5,
        6 => l.score6,
        7 => l.score7,
        8 => l.score8,
        9 => l.score9,
        10 => l.score10,
        _ => '',
      };

  /// Color de una nota (acepta promedios con decimales) como variación del
  /// color de énfasis: una nota baja sale apagada y desaturada, una alta
  /// intensa. Sobre fondo oscuro la intensidad sube aclarando; sobre papel
  /// (`light`) sube oscureciendo, para que siempre contraste con el fondo.
  /// `accent` debe venir ya ajustado al tema (ver `accentFor`).
  static Color color(num score, {required Color accent, bool light = false}) {
    final s = score.toDouble().clamp(1.0, 10.0);
    final t = (s - 1) / 9;
    final hsl = HSLColor.fromColor(accent);
    final saturation = _lerp(light ? 0.16 : 0.2, hsl.saturation, t);
    final lightness = light
        ? _lerp(hsl.lightness + 0.1, hsl.lightness - 0.07, t)
        : _lerp(hsl.lightness - 0.15, hsl.lightness + 0.13, t);
    return hsl
        .withSaturation(saturation.clamp(0.0, 1.0))
        .withLightness(lightness.clamp(0.08, 0.9))
        .toColor();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// "8,4" con coma, como se escribe en español.
  /// "8,4" en español, "8.4" en inglés.
  static String formatAverage(double value, [String localeName = 'es']) {
    final s = value.toStringAsFixed(1);
    return localeName.startsWith('en') ? s : s.replaceAll('.', ',');
  }
}

/// Ajusta el color elegido por la persona para que funcione como énfasis en
/// cada tema: sobre carbón necesita luz, sobre papel necesita cuerpo. La
/// saturación se acota para que ni un pastel ni un neón rompan la interfaz.
Color accentFor(Color seed, Brightness brightness) {
  final hsl = HSLColor.fromColor(seed);
  final dark = brightness == Brightness.dark;
  return hsl
      .withSaturation(hsl.saturation.clamp(dark ? 0.45 : 0.5, 0.9))
      .withLightness(
        hsl.lightness.clamp(dark ? 0.58 : 0.34, dark ? 0.72 : 0.44),
      )
      .toColor();
}

/// Color del texto sobre un fondo de énfasis: tinta oscura o papel claro,
/// el que más contraste (WCAG) tenga con `accent`.
Color onAccentFor(Color accent) {
  const ink = Color(0xFF1B1408);
  const paper = Color(0xFFFBF8F2);
  return contrastRatio(accent, ink) >= contrastRatio(accent, paper)
      ? ink
      : paper;
}

/// Relación de contraste WCAG 2 entre dos colores opacos (1 a 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
