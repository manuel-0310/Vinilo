import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/feed.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/streams.dart';
import '../util/tab_reselect.dart';
import '../widgets/album_strip.dart';
import '../widgets/bell_button.dart';
import '../widgets/feed_card.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_sections.dart';
import '../widgets/v_states.dart';
import 'onboarding_follow_screen.dart';
import 'routes.dart';
import 'shell_screen.dart';

/// Inicio: "VINILO" con la campana, "Popular esta semana" (carrusel con
/// "Ver todo") y "Actividad de tus amigos" (con cuántas notas nuevas hay de
/// las últimas 24 h).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.reselect});

  /// Volver a tocar "Inicio" en la barra sube hasta arriba.
  final TabReselect? reselect;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.reselect?.addListener(_toTop);
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reselect != widget.reselect) {
      oldWidget.reselect?.removeListener(_toTop);
      widget.reselect?.addListener(_toTop);
    }
  }

  @override
  void dispose() {
    widget.reselect?.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() => scrollToTop(_scroll);

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
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ConnectivityBuilder(
        builder: (context, offline, checking) => CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topPad),
                  // Sin conexión: la franja con "Reintentar" y, debajo, lo
                  // último guardado, apagado.
                  if (offline)
                    OfflineBanner(checking: checking, onRetry: () => checkConnection(context)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(VSpace.page, offline ? 12 : 6, 16, 10),
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
                ],
              ),
            ),
            SliverOpacity(
              opacity: offline ? 0.55 : 1,
              // Un solo StreamBuilder para todo: sin saber si sigo a alguien
              // no se sabe si toca el inicio vacío, y el stream de la
              // actividad admite un solo oyente.
              sliver: StreamBuilder<FollowingFeed>(
                stream: _activity,
                builder: (context, snap) {
                  if (snap.hasError) return _feedError(c, snap.error);
                  final feed = snap.data;
                  if (feed == null) return const _HomeSkeleton();
                  if (!feed.followsAnyone) return const _HomeEmpty();
                  final entries = Moderation.of(context).feed(feed.entries);
                  final fresh = freshCount(entries, DateTime.now());
                  return SliverMainAxisGroup(
                    slivers: [
                      _popularSection(),
                      SliverToBoxAdapter(
                        child: VSectionHeader(
                          l.homeFriendsActivity,
                          big: true,
                          padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 12),
                          action: fresh > 0 ? l.homeActivityNew(fresh) : null,
                          actionKey: const ValueKey('feed-new'),
                        ),
                      ),
                      _activityBody(entries),
                    ],
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: VSpace.tabBarClearance),
            ),
          ],
        ),
      ),
    );
  }

  /// "Popular esta semana" con "Ver todo"; no aparece si nadie calificó
  /// nada en la semana.
  Widget _popularSection() {
    final l = context.l10n;
    return StreamBuilder<List<AlbumStats>>(
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
                  big: true,
                  padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 12),
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
    );
  }

  Widget _activityBody(List<RatingEntry> entries) {
    final l = context.l10n;
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

/// El inicio mientras carga (prototipo "Cargando inicio"): tres portadas
/// de 130, una raya de 120 y seis filas con portada de 52, dos líneas y la
/// nota, todo bajo un mismo brillo.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  static const List<(double, double)> _widths = [
    (0.70, 0.40),
    (0.55, 0.35),
    (0.80, 0.45),
    (0.60, 0.30),
    (0.75, 0.50),
    (0.50, 0.35),
  ];

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return SliverToBoxAdapter(
      child: VShimmer(
        child: Padding(
          key: const ValueKey('home-loading'),
          padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 130,
                child: Row(
                  children: [
                    VSkeleton(width: 130, height: 130),
                    SizedBox(width: 8),
                    VSkeleton(width: 130, height: 130),
                    SizedBox(width: 8),
                    Expanded(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: 130,
                          child: VSkeleton(width: 130, height: 130),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const VSkeleton(width: 120, height: 10),
              for (final (w1, w2) in _widths)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.inkA(0.06)))),
                  child: Row(
                    children: [
                      const VSkeleton(width: 52, height: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VSkeleton(width: box.maxWidth * w1, height: 12),
                              const SizedBox(height: 8),
                              VSkeleton(width: box.maxWidth * w2, height: 9, soft: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const VSkeleton(width: 30, height: 30),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El inicio de quien todavía no sigue a nadie (prototipo "Vacío · inicio"):
/// tres huecos punteados, "Tu inicio está muy callado", la explicación,
/// "Encontrar gente" (las sugerencias del onboarding) y "Calificar un
/// disco" (la pestaña Buscar).
class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty();

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return SliverToBoxAdapter(
      child: Padding(
        key: const ValueKey('feed-empty-follow'),
        padding: const EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final side = (box.maxWidth - 16) / 3;
                return Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      DashedBox(size: side, color: c.inkA(0.22)),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(l.homeEmptyTitle, style: VText.display(46, weight: 800, height: 0.9, tracking: 0)),
            const SizedBox(height: 12),
            Text(l.homeEmptyBody, style: VText.ui(15, height: 1.45, color: c.ink2)),
            const SizedBox(height: 24),
            VPrimaryButton(
              key: const ValueKey('home-find-people'),
              label: l.homeEmptyFind,
              onPressed: () => openFindPeople(context),
            ),
            const SizedBox(height: 8),
            VSecondaryButton(
              key: const ValueKey('home-rate-album'),
              label: l.homeEmptyRate,
              onPressed: () => ShellScreen.tabRequests.value = 1,
            ),
          ],
        ),
      ),
    );
  }
}
