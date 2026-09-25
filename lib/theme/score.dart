import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Todo lo relacionado con la nota del 1 al 10: etiquetas y formato. El
/// color ya no depende de la nota: va en el énfasis o en el tono de la
/// portada (`coverTone`), según la pantalla.
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

  /// "8,4" en español, "8.4" en inglés.
  static String formatAverage(double value, [String localeName = 'es']) {
    final s = value.toStringAsFixed(1);
    return localeName.startsWith('en') ? s : s.replaceAll('.', ',');
  }
}

/// Relación de contraste WCAG 2 entre dos colores opacos (1 a 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
