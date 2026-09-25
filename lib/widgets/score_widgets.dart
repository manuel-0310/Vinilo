import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';

/// Un promedio ("8,4") sobre una portada: bloque cuadrado oscuro con el
/// número condensado en énfasis. (Las pantallas rediseñadas ponen la nota
/// junto al título, no encima de la portada.)
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.value, this.fontSize = 12, this.whole = false});

  final double value;
  final double fontSize;

  /// Nota entera ("8") en vez de promedio ("8,0").
  final bool whole;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.5, vertical: fontSize * 0.2),
      color: c.bg.withValues(alpha: 0.82),
      child: Text(
        whole ? '${value.round()}' : Score.formatAverage(value, context.l10n.localeName),
        style: VText.display(fontSize * 1.4, weight: 700, color: c.accent, height: 1),
      ),
    );
  }
}

/// Numeral grande condensado de una nota, en énfasis (o en `color`).
class ScoreNumeral extends StatelessWidget {
  const ScoreNumeral({super.key, required this.score, this.size = 40, this.color});

  final int score;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Text(
      '$score',
      style: VText.display(size, weight: 700, color: color ?? c.accent, height: 0.85),
    );
  }
}
