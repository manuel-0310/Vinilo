import 'package:flutter/material.dart';

import '../theme/score.dart';
import '../theme/vinilo_theme.dart';

/// Píldora pequeña con un promedio ("8,4").
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.value, this.fontSize = 12});

  final double value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = Score.color(value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.28),
      decoration: BoxDecoration(
        color: const Color(0xFF141210).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(fontSize),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        Score.formatAverage(value),
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
    return Text(
      '$score',
      style: VText.display(size, color: Score.color(score), height: 0.9),
    );
  }
}
