import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import 'album_cover.dart';
import 'misc.dart';
import 'score_widgets.dart';

/// Fila horizontal de portadas grandes.
class AlbumStrip extends StatelessWidget {
  const AlbumStrip({
    super.key,
    required this.albums,
    required this.heroPrefix,
    this.averages = const {},
    this.size = 140,
  });

  final List<Album> albums;
  final String heroPrefix;
  final Map<String, double> averages;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final album = albums[i];
          final heroTag = '$heroPrefix-${album.id}';
          final avg = averages[album.id];
          return GestureDetector(
            onTap: () => openAlbum(context, album, heroTag: heroTag),
            child: SizedBox(
              width: size,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AlbumCover(
                        url: album.smallCover,
                        size: size,
                        radius: 14,
                        heroTag: heroTag,
                      ),
                      if (avg != null)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: ScoreBadge(value: avg),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(13, weight: 700, height: 1.25),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    album.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12, color: VColors.text2, height: 1.3),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (50 * i).ms, duration: 400.ms)
              .slideX(begin: 0.08, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

class AlbumStripSkeleton extends StatelessWidget {
  const AlbumStripSkeleton({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: size, height: size, radius: 14),
            const SizedBox(height: 10),
            Skeleton(width: size * 0.7, height: 12, radius: 6),
            const SizedBox(height: 6),
            Skeleton(width: size * 0.45, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}
