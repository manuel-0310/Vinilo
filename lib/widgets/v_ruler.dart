import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// La escala del 1 al 10 siempre es una retícula de 10 columnas iguales;
/// estos widgets la comparten (histograma, números y celdas).

/// Distribución de notas: una barra por columna, proporcional a la más
/// votada (que llega a `height − 4`). Las columnas sin votos son una raya
/// de 2 px. Lleva la línea de base debajo.
class Histogram10 extends StatelessWidget {
  const Histogram10({
    super.key,
    required this.counts,
    required this.height,
    this.color,
    this.barMargin = 2,
    this.line = true,
  });

  /// Cuántas notas hay de cada valor (claves 1 a 10; las que faltan son 0).
  final Map<int, int> counts;
  final double height;

  /// Color de las barras (por defecto, el énfasis).
  final Color? color;

  /// Margen a cada lado de cada barra.
  final double barMargin;
  final bool line;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final most = counts.values.fold<int>(0, math.max);
    return Container(
      height: height,
      decoration: line
          ? BoxDecoration(border: Border(bottom: BorderSide(color: c.line)))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var k = 1; k <= 10; k++)
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: barMargin),
                height: (counts[k] ?? 0) == 0 || most == 0
                    ? 2
                    : math.max(2, (height - 4) * counts[k]! / most),
                color: (counts[k] ?? 0) == 0 || most == 0
                    ? c.ink.withValues(alpha: 0.2)
                    : (color ?? c.accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// Los números del 1 al 10 bajo un histograma, en mono.
class RulerNumbers extends StatelessWidget {
  const RulerNumbers({super.key, this.fontSize = 10, this.color, this.onlyEnds = false});

  final double fontSize;
  final Color? color;

  /// Solo "1" y "10" en las puntas (la ficha del artista).
  final bool onlyEnds;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final style = VText.mono(fontSize, color: color ?? c.ink4, tracking: 0);
    if (onlyEnds) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('1', style: style), Text('10', style: style)],
      );
    }
    return Row(
      children: [
        for (var k = 1; k <= 10; k++)
          Expanded(child: Text('$k', textAlign: TextAlign.center, style: style)),
      ],
    );
  }
}

/// Celdas del 1 al 10, tocables. La elegida lleva `selectedColor` y el
/// número oscuro; con `fill`, las anteriores se rellenan con ese color cada
/// vez más opaco (la regla del disco calificado).
class RulerCells extends StatelessWidget {
  const RulerCells({
    super.key,
    this.selected,
    this.onTap,
    this.height = 36,
    this.fontSize = 12,
    this.selectedColor,
    this.fill,
    this.numberColor,
    this.lines = false,
    this.selectedWeight = 600,
  });

  final int? selected;
  final ValueChanged<int>? onTap;
  final double height;
  final double fontSize;

  /// Fondo de la elegida (por defecto, el énfasis).
  final Color? selectedColor;

  /// Color de las celdas anteriores a la elegida (el de la portada).
  final Color? fill;

  /// Color de los números que no están elegidos (por defecto, tinta).
  final Color? numberColor;

  /// Líneas arriba y abajo (la escala de la bienvenida).
  final bool lines;

  /// Peso del número elegido (la bienvenida lo deja en 500).
  final int selectedWeight;

  /// Opacidad de cada celda anterior a la elegida, de la 1 a la 9.
  static const List<double> fillAlphas = [0.28, 0.34, 0.40, 0.46, 0.52, 0.58, 0.64, 0.72, 0.82];

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: lines ? BorderSide(color: c.line) : BorderSide.none,
          bottom: BorderSide(color: c.line),
        ),
      ),
      child: Row(
        children: [
          for (var k = 1; k <= 10; k++)
            Expanded(
              child: GestureDetector(
                key: ValueKey('ruler-$k'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap == null ? null : () => onTap!(k),
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  color: switch (selected) {
                    final s? when k == s => selectedColor ?? c.accent,
                    final s? when fill != null && k < s => fill!.withValues(alpha: fillAlphas[k - 1]),
                    _ => Colors.transparent,
                  },
                  child: Text(
                    '$k',
                    style: VText.mono(
                      fontSize,
                      tracking: 0,
                      weight: k == selected ? selectedWeight : 500,
                      color: k == selected ? c.onAccent : (numberColor ?? c.ink),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
