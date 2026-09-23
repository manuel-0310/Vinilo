import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import 'vinyl_disc.dart';

/// Portada de una lista: hasta cuatro carátulas en mosaico. Con una sola
/// ocupa todo; con dos, mitades; con tres, una grande y dos apiladas; con
/// cuatro, una cuadrícula. Sin portadas, un vinilo.
class ListMosaic extends StatelessWidget {
  const ListMosaic({
    super.key,
    required this.covers,
    this.size,
    this.radius = 14,
    this.shadow = false,
    this.shadowColor,
  });

  final List<String> covers;
  final double? size;
  final double radius;
  final bool shadow;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    Widget cell(String url) => Image.network(
          url,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => ColoredBox(color: c.surface2),
        );

    Widget grid;
    switch (covers.length) {
      case 0:
        grid = ColoredBox(
          color: c.surface2,
          child: Center(
            child: Opacity(
              opacity: 0.55,
              child: FractionallySizedBox(
                widthFactor: 0.42,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: VinylDisc(size: 40, labelColor: c.surface3),
                ),
              ),
            ),
          ),
        );
      case 1:
        grid = cell(covers[0]);
      case 2:
        grid = Row(
          children: [
            Expanded(child: cell(covers[0])),
            Expanded(child: cell(covers[1])),
          ],
        );
      case 3:
        grid = Row(
          children: [
            Expanded(child: cell(covers[0])),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: cell(covers[1])),
                  Expanded(child: cell(covers[2])),
                ],
              ),
            ),
          ],
        );
      default:
        grid = Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: cell(covers[0])),
                  Expanded(child: cell(covers[1])),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: cell(covers[2])),
                  Expanded(child: cell(covers[3])),
                ],
              ),
            ),
          ],
        );
    }

    Widget out = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: c.surface2, child: grid),
    );
    if (shadow) {
      out = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: (shadowColor ?? Colors.black).withValues(alpha: 0.45),
              blurRadius: 40,
              offset: const Offset(0, 22),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: out,
      );
    }
    if (size != null) return SizedBox(width: size, height: size, child: out);
    return AspectRatio(aspectRatio: 1, child: out);
  }
}
