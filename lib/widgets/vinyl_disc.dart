import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Un vinilo dibujado a mano: disco con surcos, etiqueta de color y agujero.
class VinylDisc extends StatelessWidget {
  const VinylDisc({super.key, this.size = 48, this.labelColor, this.holeColor});

  final double size;

  /// Color de la etiqueta; por defecto el acento del tema.
  final Color? labelColor;

  /// Color del agujero central; por defecto el fondo del tema.
  final Color? holeColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return CustomPaint(
      size: Size.square(size),
      painter: _VinylPainter(labelColor ?? c.accent, holeColor ?? c.bg),
    );
  }
}

class _VinylPainter extends CustomPainter {
  _VinylPainter(this.labelColor, this.holeColor);

  final Color labelColor;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2C2925), Color(0xFF0A0908)],
          stops: [0.3, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.18, 0.5, 0.68, 1],
        ).createShader(rect),
    );

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, r * 0.012)
      ..color = Colors.white.withValues(alpha: 0.055);
    final step = math.max(2.0, r * 0.05);
    for (var gr = r * 0.42; gr < r * 0.96; gr += step) {
      canvas.drawCircle(c, gr, groove);
    }

    canvas.drawCircle(c, r * 0.34, Paint()..color = labelColor);
    canvas.drawCircle(
      c,
      r * 0.34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawCircle(c, r * 0.045, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(covariant _VinylPainter old) =>
      old.labelColor != labelColor || old.holeColor != holeColor;
}

class SpinningVinyl extends StatefulWidget {
  const SpinningVinyl({
    super.key,
    this.size = 64,
    this.labelColor,
    this.period = const Duration(milliseconds: 2600),
  });

  final double size;
  final Color? labelColor;
  final Duration period;

  @override
  State<SpinningVinyl> createState() => _SpinningVinylState();
}

class _SpinningVinylState extends State<SpinningVinyl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: VinylDisc(size: widget.size, labelColor: widget.labelColor),
    );
  }
}
