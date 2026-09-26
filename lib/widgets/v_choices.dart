import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import 'v_buttons.dart';
import 'v_icons.dart';

/// Selector de Configuración (Apariencia, Idioma): celdas de 44 dentro de
/// un borde de 1 px. La elegida va rellena de énfasis; entre dos celdas no
/// elegidas hay una línea de 1 px.
class SegmentedBoxes extends StatelessWidget {
  const SegmentedBoxes({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.keys,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<String>? keys;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: c.buttonLine)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                key: keys == null ? null : ValueKey(keys![i]),
                behavior: HitTestBehavior.opaque,
                onTap: i == selected ? null : () => onChanged(i),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? c.accent : Colors.transparent,
                    border: i > 0 && i != selected && i - 1 != selected
                        ? Border(left: BorderSide(color: c.buttonLine))
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: VText.ui(
                      14,
                      weight: i == selected ? 600 : 500,
                      color: i == selected ? c.onAccent : c.ink2,
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

/// Caja para elegir entre dos opciones grandes (Lista o Ranking): borde de
/// 1 px, ícono, título y explicación. La elegida lleva borde, ícono y
/// título en énfasis y un check cuadrado de 14 px arriba a la derecha.
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final VIcon icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? c.accentText : c.inkA(0.2)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VIconView(icon, size: 22, color: selected ? c.accentText : c.inkA(0.75)),
                const SizedBox(height: 12),
                Text(title, style: VText.ui(16, weight: 600, color: selected ? c.accentText : c.ink)),
                const SizedBox(height: 3),
                Text(subtitle, style: VText.ui(12.5, color: c.ink3, height: 1.3)),
              ],
            ),
            if (selected)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  color: c.accent,
                  alignment: Alignment.center,
                  child: VIconView(VIcon.check, size: 9, color: c.onAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cuadro con borde punteado de 1 px (el "+" de "Nueva lista").
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.size, required this.color, this.child});

  final double size;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color),
      child: SizedBox.square(dimension: size, child: Center(child: child)),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    void line(Offset from, Offset to) {
      final length = (to - from).distance;
      final dir = (to - from) / length;
      for (var t = 0.0; t < length; t += dash + gap) {
        final end = t + dash > length ? length : t + dash;
        canvas.drawLine(from + dir * t, from + dir * end, paint);
      }
    }

    const h = 0.5;
    line(const Offset(0, h), Offset(size.width, h));
    line(Offset(size.width - h, 0), Offset(size.width - h, size.height));
    line(Offset(size.width, size.height - h), Offset(0, size.height - h));
    line(Offset(h, size.height), const Offset(h, 0));
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color;
}
