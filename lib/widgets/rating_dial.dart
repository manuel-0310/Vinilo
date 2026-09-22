import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/score.dart';
import '../theme/vinilo_theme.dart';

/// Selector de nota del 1 al 10 con forma de surcos de vinilo.
/// Se toca o se arrastra; cada cambio da un tic háptico.
class RatingDial extends StatelessWidget {
  const RatingDial({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  void _update(Offset local, double width) {
    final slot = ((local.dx / width) * 10).floor().clamp(0, 9) + 1;
    if (slot != value) {
      HapticFeedback.selectionClick();
      onChanged(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _update(d.localPosition, width),
          onHorizontalDragStart: (d) => _update(d.localPosition, width),
          onHorizontalDragUpdate: (d) => _update(d.localPosition, width),
          child: SizedBox(
            height: 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cajas invisibles con llave por cada nota: sirven para que
                // las pruebas automatizadas apunten a un valor concreto.
                Row(
                  children: [
                    for (var n = 1; n <= 10; n++)
                      Expanded(child: SizedBox.expand(key: ValueKey('dial-$n'))),
                  ],
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: (value ?? 0).toDouble()),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (_, position, _) => CustomPaint(
                    size: Size(width, 104),
                    painter: _DialPainter(
                      position: position,
                      color: value == null ? VColors.text3 : Score.color(value!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.position, required this.color});

  final double position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final slotWidth = size.width / 10;
    final baseline = size.height - 28;
    const minHeight = 16.0;
    const maxHeight = 40.0;

    for (var i = 0; i < 10; i++) {
      final n = i + 1;
      final x = slotWidth * (i + 0.5);
      final dist = position <= 0 ? 10.0 : (position - n).abs();
      final bump = math.exp(-(dist * dist) / 1.1);
      final h = minHeight + (maxHeight - minHeight) * bump;
      final active = position > 0 && n <= position + 0.5;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3 + bump * 1.5
        ..color = active
            ? color.withValues(alpha: 0.32 + 0.68 * bump)
            : VColors.text3.withValues(alpha: 0.32 + 0.3 * bump);
      canvas.drawLine(Offset(x, baseline - h), Offset(x, baseline), paint);

      final selected = bump > 0.6;
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: VText.ui(
            12,
            weight: selected ? 800 : 600,
            color: selected ? color : VColors.text3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, baseline + 10));
    }

    if (position > 0) {
      final kx = slotWidth * (position - 0.5);
      final ky = baseline - maxHeight - 14;
      canvas.drawCircle(
        Offset(kx, ky),
        14,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(Offset(kx, ky), 7, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.position != position || old.color != color;
}
