import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/album_grid.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

enum SearchAllKind { artists, albums }

/// "Ver todos" de los resultados de búsqueda: todos los artistas (en tres
/// columnas, círculos de 80) o todos los álbumes (en dos columnas) de una
/// búsqueda. Pide la página siguiente a Spotify al acercarse al final.
class SearchAllScreen extends StatefulWidget {
  const SearchAllScreen({super.key, required this.query, required this.kind});

  final String query;
  final SearchAllKind kind;

  @override
  State<SearchAllScreen> createState() => _SearchAllScreenState();
}

class _SearchAllScreenState extends State<SearchAllScreen> {
  final ScrollController _scroll = ScrollController();
  final List<Album> _albums = [];
  final List<Artist> _artists = [];
  final Set<String> _seen = {};

  /// Offset de la página siguiente; null cuando ya no hay más.
  int? _next = 0;
  bool _loading = false;
  bool _started = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeMore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeMore() {
    if (_error != null || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _load();
  }

  Future<void> _load() async {
    final offset = _next;
    if (offset == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spotify = ServicesScope.of(context).spotify;
      if (widget.kind == SearchAllKind.albums) {
        final page = await spotify.search(widget.query, offset: offset);
        _albums.addAll(page.items.where((a) => _seen.add(a.id)));
        _next = page.items.isEmpty ? null : page.nextOffset;
      } else {
        final page = await spotify.searchArtistsPage(widget.query, offset: offset);
        _artists.addAll(page.items.where((a) => _seen.add(a.id)));
        _next = page.items.isEmpty ? null : page.nextOffset;
      }
    } catch (e) {
      _error = e;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    // Si la página no llena la pantalla, no habrá scroll que pida la
    // siguiente: se revisa al dibujar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final albums = widget.kind == SearchAllKind.albums;
    final empty = albums ? _albums.isEmpty : _artists.isEmpty;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: VPageHeader(
                title: albums ? l.searchAllAlbums : l.searchAllArtists,
                subtitle: l.searchAllFor(widget.query),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 1,
                color: c.line,
              ),
            ),
            if (empty && _loading)
              albums ? const AlbumGridSkeleton() : const _ArtistGridSkeleton()
            else if (empty && _error == null)
              SliverToBoxAdapter(
                child: VEmptyState(title: l.searchNothingTitle, message: l.searchNothingBody),
              )
            else if (albums)
              AlbumGrid(albums: _albums, heroPrefix: 'all-${widget.query}', keyPrefix: 'all-album')
            else
              _ArtistGrid(artists: _artists),
            SliverToBoxAdapter(child: _footer(c, l, empty)),
          ],
        ),
      ),
    );
  }

  Widget _footer(ViniloPalette c, AppLocalizations l, bool empty) {
    final bottom = MediaQuery.paddingOf(context).bottom + 30;
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              empty ? describeError(_error, l) : l.loadMoreFailed(describeError(_error, l)),
              style: VText.ui(13, color: c.danger, height: 1.4),
            ),
            const SizedBox(height: 14),
            VSecondaryButton(
              key: const ValueKey('all-retry'),
              label: l.retry,
              onPressed: _load,
            ),
          ],
        ),
      );
    }
    if (_loading && !empty) {
      return Padding(
        padding: EdgeInsets.only(top: 24, bottom: bottom),
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: c.ink4),
          ),
        ),
      );
    }
    if (_next == null && !empty) {
      return Padding(
        padding: EdgeInsets.only(top: 28, bottom: bottom),
        child: VMono(l.searchEnd, color: c.ink4, align: TextAlign.center),
      );
    }
    return SizedBox(height: bottom);
  }
}

/// Artistas en tres columnas: el círculo de 80 y el nombre (13/600)
/// centrados, como la fila de los resultados.
class _ArtistGrid extends StatelessWidget {
  const _ArtistGrid({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    final rows = (artists.length + 2) ~/ 3;
    Widget cell(int i) {
      if (i >= artists.length) return const SizedBox.shrink();
      final a = artists[i];
      return GestureDetector(
        key: ValueKey('all-artist-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => openArtist(context, a),
        child: Column(
          children: [
            ArtistAvatar(artist: a, size: 80),
            const SizedBox(height: 8),
            Text(
              a.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: VText.ui(13, weight: 600, height: 1.2),
            ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      sliver: SliverList.builder(
        itemCount: rows,
        itemBuilder: (context, r) => Padding(
          padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var k = 0; k < 3; k++) ...[
                if (k > 0) const SizedBox(width: 14),
                Expanded(child: cell(3 * r + k)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistGridSkeleton extends StatelessWidget {
  const _ArtistGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      sliver: SliverList.builder(
        itemCount: 3,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: 22),
          child: Row(
            children: [
              Expanded(child: Center(child: VSkeleton(width: 80, height: 80, circle: true))),
              SizedBox(width: 14),
              Expanded(child: Center(child: VSkeleton(width: 80, height: 80, circle: true))),
              SizedBox(width: 14),
              Expanded(child: Center(child: VSkeleton(width: 80, height: 80, circle: true))),
            ],
          ),
        ),
      ),
    );
  }
}
