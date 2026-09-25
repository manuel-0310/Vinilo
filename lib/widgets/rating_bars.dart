import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vinilo_theme.dart';

/// Cómo se dibuja la columna `k` cuando la nota elegida es `selected`.
/// Fórmulas de la especificación, con `d = |k − n|`:
/// - alto = `max(30, 136 − 20·d)` px;
/// - número = `max(11, 24 − 3·d)` px;
/// - opacidad = 1 si d = 0; si no, `max(0.16, 0.62 − 0.11·(d − 1))`.
/// Sin nota elegida, todas las columnas quedan en su mínimo.
class RatingBarSpec {
  const RatingBarSpec({
    required this.height,
    required this.fontSize,
    required this.opacity,
    required this.selected,
  });

  factory RatingBarSpec.of(int k, int? selected) {
    if (selected == null) {
      return const RatingBarSpec(height: 30, fontSize: 11, opacity: 0.16, selected: false);
    }
    final d = (k - selected).abs();
    return RatingBarSpec(
      height: math.max(30, 136 - d * 20).toDouble(),
      fontSize: math.max(11, 24 - d * 3).toDouble(),
      opacity: d == 0 ? 1 : math.max(0.16, 0.62 - (d - 1) * 0.11),
      selected: d == 0,
    );
  }

  final double height;
  final double fontSize;
  final double opacity;
  final bool selected;
}

/// Las 10 barras de Calificar: se toca una o se desliza el dedo. La
/// elegida va en énfasis con el número oscuro en 700; las demás, en énfasis
/// con menos opacidad y el número en tinta. Cambia en 220 ms (ease-out) y
/// da un toque háptico por columna.
class RatingBars extends StatelessWidget {
  const RatingBars({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  static const double areaHeight = 140;
  static const double gap = 3;
  static const Duration duration = Duration(milliseconds: 220);

  void _pick(Offset local, double width) {
    final k = ((local.dx / width) * 10).floor().clamp(0, 9) + 1;
    if (k != value) {
      HapticFeedback.selectionClick();
      onChanged(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _pick(d.localPosition, width),
          onHorizontalDragStart: (d) => _pick(d.localPosition, width),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition, width),
          child: Container(
            height: areaHeight,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var k = 1; k <= 10; k++) ...[
                  if (k > 1) const SizedBox(width: gap),
                  Expanded(child: _Bar(key: ValueKey('dial-$k'), k: k, spec: RatingBarSpec.of(k, value))),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.k, required this.spec});

  final int k;
  final RatingBarSpec spec;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return AnimatedOpacity(
      duration: RatingBars.duration,
      curve: Curves.easeOut,
      opacity: spec.opacity,
      child: AnimatedContainer(
        duration: RatingBars.duration,
        curve: Curves.easeOut,
        height: spec.height,
        color: c.accent,
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 6),
        child: AnimatedDefaultTextStyle(
          duration: RatingBars.duration,
          curve: Curves.easeOut,
          style: VText.mono(
            spec.fontSize,
            tracking: 0,
            height: 1,
            weight: spec.selected ? 700 : 500,
            color: spec.selected ? c.onAccent : c.ink,
          ),
          child: Text('$k', maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
        ),
      ),
    );
  }
}
