import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';

/// Píldora pequeña con un promedio ("8,4"). Va sobre la portada, con fondo
/// oscuro en ambos temas, así que usa la variante oscura de la escala.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.value, this.fontSize = 12, this.whole = false});

  final double value;
  final double fontSize;

  /// Nota entera ("8") en vez de promedio ("8,0").
  final bool whole;

  @override
  Widget build(BuildContext context) {
    final color = VColors.of(context).scoreOnDark(value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.28),
      decoration: BoxDecoration(
        color: const Color(0xFF141210).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(fontSize),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        whole ? '${value.round()}' : Score.formatAverage(value, context.l10n.localeName),
        style: VText.ui(fontSize, weight: 800, color: color, height: 1.1),
      ),
    );
  }
}

/// Numeral grande en serif con el color de la nota.
class ScoreNumeral extends StatelessWidget {
  const ScoreNumeral({super.key, required this.score, this.size = 40});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Text(
      '$score',
      style: VText.display(size, color: c.score(score), height: 0.9),
    );
  }
}
