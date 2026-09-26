import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import 'album_cover.dart';

/// Hasta 3 portadas apiladas hacia la derecha, como discos en un estante:
/// la primera delante y cada una desplazada `offset`. Entre capas hay una
/// franja de 2 px del color del fondo (`separator`), como el `box-shadow`
/// del prototipo. Con `single` se muestra solo esa imagen (la portada que
/// eligió la autora de una lista).
class CoverStack extends StatelessWidget {
  const CoverStack({
    super.key,
    required this.urls,
    this.size = 56,
    this.offset = 10,
    this.separator,
    this.single,
  });

  final List<String?> urls;
  final double size;
  final double offset;

  /// Color de la franja entre capas (por defecto, el fondo de la app; en
  /// una hoja, `sheet`).
  final Color? separator;

  /// Portada elegida para la lista: va sola, sin capas.
  final String? single;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final width = size + 2 * offset;
    if (single != null) {
      return SizedBox(
        width: width,
        height: size,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AlbumCover(url: single, size: size),
        ),
      );
    }
    final layers = urls.take(3).toList();
    final gap = separator ?? c.bg;
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          // De atrás hacia delante.
          for (var i = layers.length - 1; i >= 0; i--) ...[
            if (i < layers.length - 1)
              Positioned(
                left: i * offset,
                top: 0,
                child: Container(width: size + 2, height: size, color: gap),
              ),
            Positioned(
              left: i * offset,
              top: 0,
              child: AlbumCover(url: layers[i], size: size),
            ),
          ],
          if (layers.isEmpty) AlbumCover(url: null, size: size),
        ],
      ),
    );
  }
}
