import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_strip.dart';
import '../widgets/feed_card.dart';
import '../widgets/misc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<List<RatingEntry>>? _feed;
  Stream<List<AlbumStats>>? _recent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_feed != null) return;
    final services = ServicesScope.of(context);
    _feed = services.ratings.feed();
    _recent = services.ratings.recentlyRated();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                VSpace.page,
                MediaQuery.paddingOf(context).top + 10,
                VSpace.page,
                0,
              ),
              child: Center(
                child: Text('Vinilo', style: VText.display(42, italic: true)),
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
                      'Popular en la comunidad',
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
          const SliverToBoxAdapter(child: SectionHeader('Actividad')),
          StreamBuilder<List<RatingEntry>>(
            stream: _feed,
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    child: Text(
                      'No se pudo cargar la actividad: ${snap.error}',
                      style: VText.ui(13, color: c.danger),
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
