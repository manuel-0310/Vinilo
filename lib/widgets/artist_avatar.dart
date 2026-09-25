import 'package:flutter/material.dart';

import '../models/artist.dart';
import '../theme/vinilo_theme.dart';

/// Foto redonda de un artista (las personas y los artistas son círculos),
/// con la inicial sobre `surface` si no hay foto. Sin `size` ocupa el
/// ancho disponible (cuadrado).
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

  /// Se ignora: el rediseño no tiene sombras. Se conserva mientras las
  /// pantallas viejas la pasen.
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final fallback = Container(
      color: c.surface,
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            artist.name.isEmpty ? '?' : artist.name.characters.first.toUpperCase(),
            style: VText.ui(40, weight: 600, color: c.ink2, height: 1),
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
    if (heroTag != null) child = Hero(tag: heroTag!, child: child);
    if (size != null) {
      return SizedBox(width: size, height: size, child: child);
    }
    return AspectRatio(aspectRatio: 1, child: child);
  }
}
