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

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: ring
            ? Border.all(color: color.withValues(alpha: 0.9), width: 2)
            : null,
      ),
      child: child,
    );
  }
}
