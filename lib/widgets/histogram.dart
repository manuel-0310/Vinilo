import 'package:flutter/material.dart';

import 'v_ruler.dart';

/// Distribución de notas del 1 al 10 con "1" y "10" en las puntas: el
/// `Histogram10` del rediseño en énfasis, con barras separadas 2 px (la
/// ficha del artista y "Cómo califico"). Se conserva la API de antes
/// mientras el perfil no se reescribe; `highlight` ya no se pinta distinto.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Histogram10(counts: hist, height: height, barMargin: 1),
        if (showAxis)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: RulerNumbers(onlyEnds: true, fontSize: 9.5),
          ),
      ],
    );
  }
}
