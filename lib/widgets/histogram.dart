import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/score.dart';
import '../theme/vinilo_theme.dart';

/// Distribución de notas del 1 al 10 en barras que crecen al aparecer.
class ScoreHistogram extends StatelessWidget {
  const ScoreHistogram({
    super.key,
    required this.hist,
    this.highlight,
    this.height = 56,
    this.showAxis = true,
  });

  final Map<int, int> hist;
  final int? highlight;
  final double height;
  final bool showAxis;

  @override
  Widget build(BuildContext context) {
    final maxCount = hist.values.fold<int>(0, math.max);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 1; i <= 10; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxCount == 0 ? 0 : (hist[i] ?? 0) / maxCount,
                      ),
                      duration: Duration(milliseconds: 500 + i * 40),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: math.max(3, v * height),
                          decoration: BoxDecoration(
                            color: highlight == i
                                ? Score.color(i)
                                : Score.color(i).withValues(
                                    alpha: (hist[i] ?? 0) == 0 ? 0.14 : 0.5,
                                  ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showAxis)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: VText.label(10)),
                Text('10', style: VText.label(10)),
              ],
            ),
          ),
      ],
    );
  }
}
