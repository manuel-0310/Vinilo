import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Avatar de una persona: siempre un círculo. Con foto, la foto; sin foto,
/// la inicial en tinta sobre su color apagado (`personTone`), o sobre su
/// color tal cual con la inicial oscura si `filled` (Configuración). Con
/// `ring`, un aro de 4 px del color del fondo lo separa del banner, por
/// fuera del círculo (el tamaño total es `size + 8`).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.color,
    this.url,
    this.bytes,
    this.size = 40,
    this.ring = false,
    this.filled = false,
    this.initialSize,
  });

  final String name;
  final Color color;
  final String? url;
  final Uint8List? bytes;
  final double size;
  final bool ring;
  final bool filled;

  /// Tamaño de la inicial cuando no hay foto (por defecto, 39 % del
  /// avatar; el de 22 del inicio la lleva en 11).
  final double? initialSize;

  static const double ringWidth = 4;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: VText.ui(
          initialSize ?? size * 0.39,
          weight: filled ? 700 : 600,
          color: filled ? c.onAccent : c.ink,
          height: 1,
        ),
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

    Widget avatar = SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: filled ? color : c.personTone(color),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
    if (ring) {
      avatar = Container(
        padding: const EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
        child: avatar,
      );
    }
    return avatar;
  }
}
