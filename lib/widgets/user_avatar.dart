import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.color,
    this.url,
    this.bytes,
    this.size = 40,
    this.ring = false,
  });

  final String name;
  final Color color;
  final String? url;
  final Uint8List? bytes;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: VText.display(size * 0.52, color: color, height: 1),
      ),
    );

    Widget child = fallback;
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      child = Image.network(
        url!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    Widget avatar = ClipOval(
      child: ColoredBox(
        color: color.withValues(alpha: 0.2),
        child: SizedBox.expand(child: child),
      ),
    );
    if (ring) {
      // El anillo se pinta encima de la foto. Como borde de la decoración
      // normal encogía la imagen hacia dentro y dejaba ver el fondo claro
      // alrededor (los "espacios en blanco" del encabezado del perfil).
      avatar = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
        ),
        child: avatar,
      );
    }
    return SizedBox(width: size, height: size, child: avatar);
  }
}
