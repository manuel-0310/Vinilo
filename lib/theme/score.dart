import 'package:flutter/material.dart';

/// Todo lo relacionado con la nota del 1 al 10: etiquetas, color y formato.
class Score {
  Score._();

  static const int min = 1;
  static const int max = 10;

  static const Map<int, String> labels = {
    1: 'Insufrible',
    2: 'Malo',
    3: 'Flojo',
    4: 'Meh',
    5: 'Regular',
    6: 'Está bien',
    7: 'Bueno',
    8: 'Muy bueno',
    9: 'Excelente',
    10: 'Obra maestra',
  };

  static String label(int score) => labels[score] ?? '';

  static const Map<int, Color> _stops = {
    1: Color(0xFFB8544D),
    3: Color(0xFFC97540),
    5: Color(0xFFD99A3A),
    7: Color(0xFFE3B94E),
    9: Color(0xFFEDD37D),
    10: Color(0xFFF7E9B4),
  };

  /// Color de una nota (acepta promedios con decimales).
  static Color color(num score) {
    final s = score.toDouble().clamp(1.0, 10.0);
    final keys = _stops.keys.toList()..sort();
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i];
      final b = keys[i + 1];
      if (s >= a && s <= b) {
        return Color.lerp(_stops[a], _stops[b], (s - a) / (b - a))!;
      }
    }
    return _stops[10]!;
  }

  /// "8,4" con coma, como se escribe en español.
  static String formatAverage(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}
