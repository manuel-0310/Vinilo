import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Portada: siempre cuadrada y de esquinas rectas, con un fundido al
/// cargar. Mientras no hay imagen (o no carga) se ve el relleno liso de
/// `surface`.
class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    required this.url,
    this.size,
    this.radius = 0,
    this.heroTag,
    this.shadow = false,
    this.shadowColor,
    this.fit = BoxFit.cover,
    this.placeholderColor,
  });

  final String? url;
  final double? size;

  /// Se ignoran: el rediseño no tiene esquinas redondeadas ni sombras. Se
  /// conservan mientras las pantallas viejas los pasen.
  final double radius;
  final bool shadow;
  final Color? shadowColor;
  final String? heroTag;
  final BoxFit fit;

  /// Relleno mientras no hay imagen (por defecto, `surface`): la rejilla de
  /// la bienvenida usa los colores planos del prototipo.
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final placeholder = ColoredBox(color: placeholderColor ?? c.surface);

    Widget image = url == null
        ? placeholder
        : Stack(
            fit: StackFit.expand,
            children: [
              placeholder,
              Image.network(
                url!,
                fit: fit,
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

    image = ClipRect(child: image);

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    if (size != null) {
      return SizedBox(width: size, height: size, child: image);
    }
    return AspectRatio(aspectRatio: 1, child: image);
  }
}
