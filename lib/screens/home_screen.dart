import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../widgets/album_strip.dart';
import '../widgets/feed_card.dart';
import '../widgets/misc.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<List<RatingEntry>>? _feed;
  Stream<List<AlbumStats>>? _recent;
  Future<AlbumPage>? _fresh;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_feed != null) return;
    final services = ServicesScope.of(context);
    _feed = services.ratings.feed();
    _recent = services.ratings.recentlyRated();
    _fresh = services.spotify.newAlbums();
  }

  void _retryFresh() {
    final future = ServicesScope.of(context).spotify.newAlbums();
    setState(() {
      _fresh = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = CurrentUser.of(context);
    final year = DateTime.now().year;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                VSpace.page,
                MediaQuery.paddingOf(context).top + 14,
                VSpace.page,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vinilo', style: VText.display(42, italic: true)),
                        Text(
                          '${greeting()}, ${me.name}',
                          style: VText.ui(14, color: VColors.text2),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigate(2),
                    child: UserAvatar(
                      name: me.name,
                      color: me.color,
                      url: me.avatarUrl,
                      size: 44,
                      ring: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<AlbumStats>>(
            stream: _recent,
            builder: (context, snap) {
              final albums = snap.data ?? const <AlbumStats>[];
              if (albums.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      'Sonando en la comunidad',
                      subtitle: 'Lo último que la gente puso en su diario',
                    ),
                    AlbumStrip(
                      albums: albums.map((a) => a.album).toList(),
                      averages: {for (final a in albums) a.album.id: a.average},
                      heroPrefix: 'recent',
                    ),
                  ],
                ),
              );
            },
          ),
          FutureBuilder<AlbumPage>(
            future: _fresh,
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader('Lo nuevo de $year'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${snap.error}',
                                style: VText.ui(13, color: VColors.danger),
                              ),
                            ),
                            TextButton(
                              onPressed: _retryFresh,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              final items = snap.data?.items ?? const <Album>[];
              if (snap.connectionState != ConnectionState.done) {
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        'Lo nuevo de $year',
                        subtitle: 'Álbumes recién salidos en Spotify',
                      ),
                      const AlbumStripSkeleton(),
                    ],
                  ),
                );
              }
              if (items.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      'Lo nuevo de $year',
                      subtitle: 'Álbumes recién salidos en Spotify',
                    ),
                    AlbumStrip(albums: items, heroPrefix: 'fresh'),
                  ],
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              'Actividad',
              subtitle: 'El diario de toda la comunidad',
            ),
          ),
          StreamBuilder<List<RatingEntry>>(
            stream: _feed,
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    child: Text(
                      'No se pudo cargar la actividad: ${snap.error}',
                      style: VText.ui(13, color: VColors.danger),
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                  sliver: SliverList.separated(
                    itemCount: 3,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, _) =>
                        const Skeleton(height: 170, radius: 24),
                  ),
                );
              }
              final entries = snap.data!;
              if (entries.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Nadie ha puesto la primera nota',
                    message:
                        'Busca un disco que te haya marcado y estrena el diario de la comunidad.',
                    action: FilledButton.icon(
                      onPressed: () => widget.onNavigate(1),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Buscar un disco'),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    return FeedCard(
                      entry: entry,
                      heroTag: 'feed-${entry.id}',
                      index: i,
                    )
                        .animate()
                        .fadeIn(delay: (40 * (i % 8)).ms, duration: 380.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
                  },
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: VSpace.tabBarClearance),
          ),
        ],
      ),
    );
  }
}
