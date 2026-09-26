import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Física de las pantallas con portada arriba (disco, perfil, lista y
/// artista): rebota en iOS y en Android, así existe el desplazamiento
/// negativo al tirar hacia abajo estando arriba del todo.
const ScrollPhysics pullPhysics = BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

/// Cuánto se tiró hacia abajo estando arriba del todo (lo que el rebote
/// deja por encima del contenido); 0 si no.
double pullExtent(ScrollController controller) {
  if (!controller.hasClients) return 0;
  final position = controller.positions.first;
  if (!position.hasPixels || !position.hasContentDimensions) return 0;
  return math.max(0, position.minScrollExtent - position.pixels);
}

/// Escala de algo de `height` de alto para que, estirado desde su borde de
/// abajo, crezca `extra` hacia arriba.
double pullScale(double height, double extra) => height <= 0 ? 1 : (height + extra) / height;

/// Crece al tirar hacia abajo: se escala desde el centro de su borde de
/// abajo, así su borde de arriba sube lo mismo que baja el contenido y, si
/// está arriba del todo (la portada del disco, el banner del perfil, la
/// franja de la lista), sigue pegado al borde de la pantalla sin dejar ver
/// el fondo. Al soltar vuelve con el rebote. `height` es su alto sin
/// estirar. En reposo la escala es 1 y el árbol no cambia (una `Hero` o
/// una imagen de dentro no se vuelven a montar).
class PullStretch extends StatelessWidget {
  const PullStretch({
    super.key,
    required this.controller,
    required this.height,
    required this.child,
  });

  final ScrollController controller;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.scale(
        scale: pullScale(height, pullExtent(controller)),
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: child,
    );
  }
}

/// Se queda quieto al tirar hacia abajo (los botones que van encima de la
/// portada o del banner); al desplazarse normalmente se mueve con todo.
class PullPinned extends StatelessWidget {
  const PullPinned({super.key, required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -pullExtent(controller)),
        child: child,
      ),
      child: child,
    );
  }
}
