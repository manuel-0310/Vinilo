import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/album_grid.dart';
import '../widgets/v_sections.dart';

/// "Ver todo" de Popular esta semana: los discos más calificados de los
/// últimos 7 días en dos columnas, con su media.
class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  Stream<List<AlbumStats>>? _popular;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _popular ??= ServicesScope.of(context).ratings.popularThisWeek(limit: 60);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<AlbumStats>>(
          stream: _popular,
          builder: (context, snap) {
            final albums = snap.data;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: VPageHeader(title: l.popularTitle, subtitle: l.popularSubtitle),
                ),
                if (snap.hasError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                      child: Text(
                        describeError(snap.error, l),
                        style: VText.ui(13, color: c.danger),
                      ),
                    ),
                  )
                else if (albums == null)
                  const AlbumGridSkeleton()
                else if (albums.isEmpty)
                  SliverToBoxAdapter(
                    child: VEmptyState(
                      title: l.popularEmptyTitle,
                      message: l.popularEmptyBody,
                    ),
                  )
                else
                  AlbumGrid(
                    albums: [for (final a in albums) a.album],
                    averages: {for (final a in albums) a.album.id: a.average},
                    heroPrefix: 'popular-all',
                    keyPrefix: 'popular-item',
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 30),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
