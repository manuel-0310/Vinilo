import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../screens/routes.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import 'album_cover.dart';
import 'v_sections.dart';

/// Carrusel de portadas de 136 ("Popular esta semana", "Más de…"): la
/// portada, el título (14/600) y el artista (12) y, si la hay, la media en
/// 28 condensada y en énfasis a la derecha.
class AlbumStrip extends StatelessWidget {
  const AlbumStrip({
    super.key,
    required this.albums,
    required this.heroPrefix,
    this.averages = const {},
    this.size = 136,
    this.keyPrefix = 'strip',
  });

  final List<Album> albums;
  final String heroPrefix;
  final Map<String, double> averages;
  final double size;

  /// Llaves de prueba: `{keyPrefix}-N`.
  final String keyPrefix;

  /// Portada, 8 de aire y la fila del título (título 15,2 + 2 + artista 13).
  static double heightFor(double size) => size + 8 + 31;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(size),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final album = albums[i];
          final heroTag = '$heroPrefix-${album.id}';
          return GestureDetector(
            key: ValueKey('$keyPrefix-$i'),
            onTap: () => openAlbum(context, album, heroTag: heroTag),
            child: SizedBox(
              width: size,
              child: AlbumTile(
                album: album,
                average: averages[album.id],
                heroTag: heroTag,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Una portada con su título y artista debajo y, si la hay, la media a la
/// derecha (el carrusel del inicio y la cuadrícula de Popular). Sin media,
/// el artista lleva el año: "Artista · 2025" (los resultados de búsqueda).
class AlbumTile extends StatelessWidget {
  const AlbumTile({
    super.key,
    required this.album,
    this.average,
    this.heroTag,
    this.subtitleSize = 12,
  });

  final Album album;
  final double? average;
  final String? heroTag;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final avg = average;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AlbumCover(url: album.smallCover, heroTag: heroTag),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(14, weight: 600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    avg == null ? album.subtitle : album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(subtitleSize, color: c.ink3),
                  ),
                ],
              ),
            ),
            if (avg != null) ...[
              const SizedBox(width: 6),
              Text(
                Score.formatAverage(avg, context.l10n.localeName),
                style: VText.display(28, weight: 700, stretch: 65, height: 0.9, tracking: 0, color: c.accent),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Mientras carga el carrusel: portadas planas que laten.
class AlbumStripSkeleton extends StatelessWidget {
  const AlbumStripSkeleton({super.key, this.size = 136});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AlbumStrip.heightFor(size),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VSkeleton(width: size, height: size),
            const SizedBox(height: 10),
            VSkeleton(width: size * 0.7, height: 11),
            const SizedBox(height: 6),
            VSkeleton(width: size * 0.45, height: 9),
          ],
        ),
      ),
    );
  }
}
