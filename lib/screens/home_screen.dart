import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/feed.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/streams.dart';
import '../widgets/album_strip.dart';
import '../widgets/bell_button.dart';
import '../widgets/feed_card.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// Inicio: "VINILO" con la campana, "Popular esta semana" (carrusel con
/// "Ver todo") y "Actividad de tus amigos" (con cuántas notas nuevas hay de
/// las últimas 24 h).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<List<AlbumStats>>? _popular;

  // La actividad depende de a quién sigo. Es un solo stream que se escucha
  // una vez: por dentro rehace la consulta cuando cambia esa lista (seguir,
  // dejar de seguir y volver a seguir no vuelve a escuchar el mismo).
  Stream<FollowingFeed>? _activity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_popular != null) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    _popular = services.ratings.popularThisWeek();
    _activity = switchLatest(
      services.follows.followingIds(me.uid).distinct(listEquals),
      (List<String> uids) => uids.isEmpty
          ? Stream.value(const FollowingFeed.nobody())
          : services.ratings
              .feedFor(uids)
              .map((e) => FollowingFeed(followsAnyone: true, entries: e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                VSpace.page,
                MediaQuery.paddingOf(context).top + 6,
                16,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.appName.toUpperCase(),
                      style: VText.display(36, weight: 900, height: 0.9, tracking: 0),
                    ),
                  ),
                  const BellButton(),
                ],
              ),
            ),
          ),
          StreamBuilder<List<AlbumStats>>(
            stream: _popular,
            builder: (context, snap) {
              final albums = snap.data;
              if (albums != null && albums.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VSectionHeader(
                        l.homePopularWeek,
                        action: l.seeAll,
                        onAction: () => openPopular(context),
                        actionKey: const ValueKey('popular-all'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: albums == null
                            ? const AlbumStripSkeleton()
                            : AlbumStrip(
                                albums: albums.map((a) => a.album).toList(),
                                averages: {for (final a in albums) a.album.id: a.average},
                                heroPrefix: 'popular',
                                keyPrefix: 'popular',
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Un solo StreamBuilder para el encabezado ("N nuevas") y la
          // lista: el stream de la actividad admite un solo oyente.
          StreamBuilder<FollowingFeed>(
            stream: _activity,
            builder: (context, snap) {
              final entries = snap.data?.entries ?? const <RatingEntry>[];
              final fresh = freshCount(entries, DateTime.now());
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: VSectionHeader(
                      l.homeFriendsActivity,
                      action: fresh > 0 ? l.homeActivityNew(fresh) : null,
                      actionKey: const ValueKey('feed-new'),
                    ),
                  ),
                  _activityBody(c, snap),
                ],
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

  Widget _activityBody(ViniloPalette c, AsyncSnapshot<FollowingFeed> snap) {
    final l = context.l10n;
    if (snap.hasError) return _feedError(c, snap.error);
    if (!snap.hasData) return const _FeedSkeleton();
    final feed = snap.data!;
    if (!feed.followsAnyone) {
      return SliverToBoxAdapter(
        child: VEmptyState(
          key: const ValueKey('feed-empty-follow'),
          title: l.homeFollowTitle,
          message: l.homeFollowBody,
          padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 24),
        ),
      );
    }
    final entries = feed.entries;
    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: VEmptyState(
          key: const ValueKey('feed-empty-quiet'),
          title: l.homeQuietTitle,
          message: l.homeQuietBody,
          padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 24),
        ),
      );
    }
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return FeedCard(
          entry: entry,
          heroTag: 'feed-${entry.id}',
          index: i,
          first: i == 0,
          last: i == entries.length - 1,
        );
      },
    );
  }

  Widget _feedError(ViniloPalette c, Object? error) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 0),
        child: Text(
          context.l10n.homeActivityError(describeError(error, context.l10n)),
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
      padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 0),
      sliver: SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            VSkeleton(width: 76, height: 76),
            SizedBox(width: 14),
            Expanded(child: VSkeleton(height: 40)),
            SizedBox(width: 14),
            VSkeleton(width: 36, height: 52),
          ],
        ),
      ),
    );
  }
}
