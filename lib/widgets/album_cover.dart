import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import 'vinyl_disc.dart';

/// Portada cuadrada con esquinas redondeadas, fundido al cargar y
/// marcador de posición con un vinilo cuando no hay imagen.
class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    required this.url,
    this.size,
    this.radius = 12,
    this.heroTag,
    this.shadow = false,
    this.shadowColor,
  });

  final String? url;
  final double? size;
  final double radius;
  final String? heroTag;
  final bool shadow;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: VColors.surface2,
      child: Center(
        child: Opacity(
          opacity: 0.55,
          child: FractionallySizedBox(
            widthFactor: 0.42,
            child: const AspectRatio(
              aspectRatio: 1,
              child: VinylDisc(size: 40, labelColor: VColors.surface3),
            ),
          ),
        ),
      ),
    );

    Widget image = url == null
        ? placeholder
        : Stack(
            fit: StackFit.expand,
            children: [
              placeholder,
              Image.network(
                url!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, _, _) => placeholder,
              ),
            ],
          );

    image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );

    if (shadow) {
      image = DecoratedBox(
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
        child: image,
      );
    }

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    if (size != null) {
      return SizedBox(width: size, height: size, child: image);
    }
    return AspectRatio(aspectRatio: 1, child: image);
  }
}
