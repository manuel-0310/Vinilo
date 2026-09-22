import 'package:flutter/material.dart';

import '../models/artist.dart';
import '../theme/vinilo_theme.dart';

/// Foto redonda de un artista con la inicial de respaldo. Sin `size` ocupa
/// el ancho disponible (cuadrado).
class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({
    super.key,
    required this.artist,
    this.size,
    this.heroTag,
    this.shadowColor,
  });

  final Artist artist;
  final double? size;
  final String? heroTag;

  /// Con color, la foto lleva una sombra de ese color (ficha del artista).
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final fallback = Container(
      color: c.surface2,
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            artist.name.isEmpty ? '?' : artist.name.characters.first.toUpperCase(),
            style: VText.display(40, color: c.text2, height: 1),
          ),
        ),
      ),
    );
    final url = size != null && size! <= 64 ? artist.smallImage : artist.bestImage;
    Widget child = ClipOval(
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
    if (shadowColor != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor!.withValues(alpha: 0.45),
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
        child: child,
      );
    }
    if (heroTag != null) child = Hero(tag: heroTag!, child: child);
    if (size != null) {
      return SizedBox(width: size, height: size, child: child);
    }
    return AspectRatio(aspectRatio: 1, child: child);
  }
}
