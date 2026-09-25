import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Barra inferior del rediseño: 3 pestañas de solo texto, línea de 1 px
/// arriba y, sobre la activa, una raya de énfasis de 2×32. Mide 50 más la
/// zona segura de abajo (84 en un iPhone con indicador de inicio).
class VBottomBar extends StatelessWidget {
  const VBottomBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.keys,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<String>? keys;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    key: keys == null ? null : ValueKey(keys![i]),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(i),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 2,
                          color: i == selected ? c.accent : Colors.transparent,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          labels[i],
                          style: VText.ui(
                            13,
                            weight: i == selected ? 600 : 500,
                            color: i == selected ? c.ink : c.inactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
