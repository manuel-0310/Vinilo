import 'package:flutter/material.dart';

import '../models/album.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';
import 'album_strip.dart';
import 'v_sections.dart';

/// Discos en dos columnas (separación de 18 entre filas y 12 entre
/// columnas): los resultados de búsqueda, Popular y "Ver todos". Va en filas
/// de dos para que cada una tome el alto de su contenido.
class AlbumGrid extends StatelessWidget {
  const AlbumGrid({
    super.key,
    required this.albums,
    required this.heroPrefix,
    this.averages = const {},
    this.keyPrefix = 'album',
    this.onOpen,
  });

  final List<Album> albums;
  final String heroPrefix;

  /// Con media, cada disco la lleva a la derecha del título.
  final Map<String, double> averages;

  /// Llaves de prueba: `{keyPrefix}-N`.
  final String keyPrefix;

  /// Qué hacer al tocar un disco (por defecto, abrirlo).
  final void Function(Album album, String heroTag)? onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (albums.length + 1) ~/ 2;
    Widget tile(int i) {
      if (i >= albums.length) return const SizedBox.shrink();
      final album = albums[i];
      final heroTag = '$heroPrefix-${album.id}';
      final avg = averages[album.id];
      return GestureDetector(
        key: ValueKey('$keyPrefix-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onOpen != null
            ? onOpen!(album, heroTag)
            : openAlbum(context, album, heroTag: heroTag),
        child: AlbumTile(
          album: album,
          average: avg,
          heroTag: heroTag,
          subtitleSize: avg == null ? 12.5 : 12,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      sliver: SliverList.builder(
        itemCount: rows,
        itemBuilder: (context, r) => Padding(
          padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile(2 * r)),
              const SizedBox(width: 12),
              Expanded(child: tile(2 * r + 1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mientras cargan: cuadros planos que laten, en las mismas dos columnas.
class AlbumGridSkeleton extends StatelessWidget {
  const AlbumGridSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    Widget tile() => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1, child: VSkeleton()),
            SizedBox(height: 10),
            VSkeleton(width: 110, height: 11),
            SizedBox(height: 6),
            VSkeleton(width: 70, height: 9),
          ],
        );
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      sliver: SliverList.builder(
        itemCount: rows,
        itemBuilder: (_, r) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile()),
              const SizedBox(width: 12),
              Expanded(child: tile()),
            ],
          ),
        ),
      ),
    );
  }
}
