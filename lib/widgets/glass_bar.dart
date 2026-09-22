import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Imitación en Dart puro de una barra con Liquid Glass: desenfoque fuerte,
/// tinte translúcido, borde con degradado que simula el filo del vidrio,
/// un reflejo especular arriba y una sombra suave que la despega del fondo.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.height = 64,
    this.radius = 34,
    this.tint,
  });

  final Widget child;
  final double height;
  final double radius;

  /// Color del vidrio; por defecto la superficie del tema.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final tint = this.tint ?? c.surface;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.45 : 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.compose(
            outer: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            inner: const ui.ColorFilter.matrix(<double>[
              1.25, 0, 0, 0, 0, //
              0, 1.25, 0, 0, 0, //
              0, 0, 1.25, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
          ),
          child: Stack(
            children: [
              // Tinte del vidrio: más claro arriba, más denso abajo.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        tint.withValues(alpha: 0.42),
                        tint.withValues(alpha: 0.55),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
              // Reflejo especular en el borde superior.
              Positioned(
                top: 0,
                left: radius * 0.6,
                right: radius * 0.6,
                height: 1.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              // Filo del vidrio: borde con degradado diagonal.
              Positioned.fill(
                child: CustomPaint(painter: _GlassEdgePainter(shape)),
              ),
              SizedBox(height: height, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  _GlassEdgePainter(this.shape);

  final BorderRadius shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = shape.toRRect(rect).deflate(0.75);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.30),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter old) => old.shape != shape;
}
