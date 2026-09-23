import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/feed.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/streams.dart';
import '../widgets/album_strip.dart';
import '../widgets/bell_button.dart';
import '../widgets/feed_card.dart';
import '../widgets/misc.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<List<AlbumStats>>? _recent;

  // La actividad depende de a quién sigo. Es un solo stream que se escucha
  // una vez: por dentro rehace la consulta cuando cambia esa lista (seguir,
  // dejar de seguir y volver a seguir no vuelve a escuchar el mismo).
  Stream<FollowingFeed>? _activity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recent != null) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    _recent = services.ratings.recentlyRated();
    _activity = switchLatest(
      services.follows.followingIds(me.uid).distinct(listEquals),
      (List<String> uids) => uids.isEmpty
          ? Stream.value(const FollowingFeed.nobody())
          : services.ratings
              .feedFor(uids)
              .map((e) => FollowingFeed(followsAnyone: true, entries: e)),
    );
  }

  void _findPeople() {
    SearchScreen.focusRequests.value = true;
    widget.onNavigate(1);
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text('Vinilo', style: VText.display(42, italic: true)),
                  const Positioned(right: 0, child: BellButton()),
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
                    const SectionHeader('Popular'),
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
          const SliverToBoxAdapter(
            child: SectionHeader(
              'Actividad',
              subtitle: 'De tus amigos',
            ),
          ),
          StreamBuilder<FollowingFeed>(
            stream: _activity,
            builder: (context, snap) {
              if (snap.hasError) return _feedError(c, snap.error);
              if (!snap.hasData) return const _FeedSkeleton();
              final feed = snap.data!;
              if (!feed.followsAnyone) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    key: const ValueKey('feed-empty-follow'),
                    title: 'Sigue a tus amigos',
                    message:
                        'Aquí verás lo que califican las personas que sigues. Búscalas por su nombre o su @usuario.',
                    action: FilledButton.icon(
                      key: const ValueKey('find-people'),
                      onPressed: _findPeople,
                      icon: const Icon(Icons.person_search_rounded),
                      label: const Text('Buscar personas'),
                    ),
                  ),
                );
              }
              final entries = feed.entries;
              if (entries.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyState(
                    key: ValueKey('feed-empty-quiet'),
                    title: 'Todo tranquilo por aquí',
                    message:
                        'Las personas que sigues todavía no han calificado nada. Cuando lo hagan, aparecerá aquí.',
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

  Widget _feedError(ViniloPalette c, Object? error) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        child: Text(
          'No se pudo cargar la actividad: $error',
          style: VText.ui(13, color: c.danger),
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      sliver: SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => const Skeleton(height: 170, radius: 24),
      ),
    );
  }
}
