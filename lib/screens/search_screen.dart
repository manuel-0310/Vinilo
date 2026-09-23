import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/misc.dart';
import '../widgets/person_row.dart';
import 'routes.dart';

const _suggestions = [
  'Radiohead',
  'Bad Bunny',
  'Rosalía',
  'Kendrick Lamar',
  'Soda Stereo',
  'Björk',
  'Frank Ocean',
  'Café Tacvba',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// Pide al buscador que tome el foco y sugiera buscar personas (lo usa el
  /// inicio cuando todavía no sigues a nadie).
  static final ValueNotifier<bool> focusRequests = ValueNotifier(false);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _requestId = 0;

  String _query = '';
  AlbumPage? _page;
  List<Artist>? _artists;
  List<PersonInfo>? _people;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    SearchScreen.focusRequests.addListener(_onFocusRequest);
  }

  @override
  void dispose() {
    SearchScreen.focusRequests.removeListener(_onFocusRequest);
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocusRequest() {
    if (!SearchScreen.focusRequests.value || !mounted) return;
    SearchScreen.focusRequests.value = false;
    // La pestaña acaba de cambiar; el campo necesita un cuadro para existir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _requestId++;
      setState(() {
        _query = '';
        _page = null;
        _artists = null;
        _people = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    final id = ++_requestId;
    setState(() {
      _query = q;
      _loading = true;
      _error = null;
    });
    try {
      // Álbumes, artistas y personas a la vez; si solo falla la búsqueda de
      // artistas o de personas, se muestran los álbumes igual. Con "@"
      // delante solo se buscan personas.
      final services = ServicesScope.of(context);
      final me = CurrentUser.maybeOf(context);
      final people = services.users
          .searchPeople(q, excludeUid: me?.uid)
          .catchError((_) => <PersonInfo>[]);
      if (q.startsWith('@')) {
        final foundPeople = await people;
        if (id != _requestId || !mounted) return;
        setState(() {
          _page = const AlbumPage(items: [], total: 0);
          _artists = const [];
          _people = foundPeople;
          _loading = false;
        });
        return;
      }
      final spotify = services.spotify;
      final albums = spotify.search(q);
      final artists = spotify.searchArtists(q).catchError((_) => <Artist>[]);
      final result = await albums;
      final found = await artists;
      final foundPeople = await people;
      if (id != _requestId || !mounted) return;
      setState(() {
        _page = result;
        _artists = found;
        _people = foundPeople;
        _loading = false;
      });
    } catch (e) {
      if (id != _requestId || !mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final next = _page?.nextOffset;
    if (next == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    final id = _requestId;
    try {
      final more =
          await ServicesScope.of(context).spotify.search(_query, offset: next);
      if (id != _requestId || !mounted) return;
      setState(() => _page = _page!.merge(more));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar más: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _submit(String q) {
    final text = q.trim();
    if (text.isEmpty) return;
    _debounce?.cancel();
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _focus.unfocus();
    _search(text);
    _remember(text);
  }

  void _remember(String q) {
    final me = CurrentUser.maybeOf(context);
    if (me == null) return;
    ServicesScope.of(context).users.rememberSearch(me.uid, q, me.recentSearches);
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final me = CurrentUser.of(context);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 14, VSpace.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buscar', style: VText.display(42)),
                  const SizedBox(height: 14),
                  TextField(
                    key: const ValueKey('search-field'),
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                    style: VText.ui(16, weight: 600),
                    decoration: InputDecoration(
                      hintText: 'Álbum, artista o @persona',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: c.text3,
                      ),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _clear,
                              icon: Icon(
                                Icons.close_rounded,
                                color: c.text3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: _Suggestions(
                recent: me.recentSearches,
                onPick: _submit,
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: EmptyState(
                title: 'Spotify no respondió',
                message: '$_error',
                labelColor: c.danger,
                action: TextButton(
                  onPressed: () => _search(_query),
                  child: const Text('Reintentar'),
                ),
              ),
            )
          else if (_loading && _page == null)
            const _GridSkeleton()
          else if (_page != null &&
              _page!.items.isEmpty &&
              (_artists?.isEmpty ?? true) &&
              (_people?.isEmpty ?? true))
            SliverToBoxAdapter(
              child: EmptyState(
                title: 'Nada por aquí',
                message: _query.startsWith('@')
                    ? 'Nadie tiene un @usuario que empiece así.'
                    : 'Prueba con otro nombre, o busca por el artista.',
              ),
            )
          else if (_page != null) ...[
            if (_people != null && _people!.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Personas', top: 22),
                    for (final (i, p) in _people!.indexed)
                      PersonRow(key: ValueKey('person-hit-$i'), person: p)
                          .animate()
                          .fadeIn(delay: (40 * i).ms, duration: 380.ms)
                          .slideX(begin: 0.05, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            if (_artists != null && _artists!.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      'Artistas',
                      top: _people != null && _people!.isNotEmpty ? 26 : 22,
                    ),
                    _ArtistStrip(artists: _artists!),
                  ],
                ),
              ),
            if (_page!.items.isNotEmpty)
              SliverToBoxAdapter(
                child: SectionHeader(
                  'Álbumes',
                  top: (_artists != null && _artists!.isNotEmpty) ||
                          (_people != null && _people!.isNotEmpty)
                      ? 26
                      : 22,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.76,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final album = _page!.items[i];
                    return _ResultTile(
                      key: ValueKey('result-$i'),
                      album: album,
                      index: i,
                      onTap: () {
                        _remember(_query);
                        openAlbum(context, album, heroTag: 'search-${album.id}');
                      },
                    );
                  },
                  childCount: _page!.items.length,
                ),
              ),
            ),
            if (_page!.items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                child: Center(
                  child: _loadingMore
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _page!.nextOffset == null
                          ? Text(
                              _loading ? '' : 'Eso es todo lo que encontró Spotify',
                              style: VText.ui(12, color: c.text3),
                            )
                          : Pill(
                              onTap: _loadMore,
                              child: Text(
                                'Cargar más',
                                style: VText.ui(13, weight: 700),
                              ),
                            ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: VSpace.tabBarClearance),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    super.key,
    required this.album,
    required this.index,
    required this.onTap,
  });

  final Album album;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumCover(
            url: album.smallCover,
            radius: 14,
            heroTag: 'search-${album.id}',
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VText.ui(14, weight: 700, height: 1.25),
          ),
          const SizedBox(height: 2),
          Text(
            album.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VText.ui(12, color: c.text2, height: 1.3),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (35 * (index % 10)).ms, duration: 380.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

/// Fila horizontal de artistas encontrados: foto redonda y nombre.
class _ArtistStrip extends StatelessWidget {
  const _ArtistStrip({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: artists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final a = artists[i];
          return GestureDetector(
            key: ValueKey('artist-hit-$i'),
            onTap: () => openArtist(context, a),
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  ArtistAvatar(artist: a, size: 84),
                  const SizedBox(height: 8),
                  Text(
                    a.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: VText.ui(12, weight: 700, height: 1.2),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (40 * i).ms, duration: 380.ms)
              .slideX(begin: 0.08, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(VSpace.page, 22, VSpace.page, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 22,
          crossAxisSpacing: 14,
          childAspectRatio: 0.76,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AspectRatio(aspectRatio: 1, child: Skeleton(radius: 14)),
              SizedBox(height: 10),
              Skeleton(width: 120, height: 12, radius: 6),
              SizedBox(height: 6),
              Skeleton(width: 80, height: 10, radius: 5),
            ],
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.recent, required this.onPick});

  final List<String> recent;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpace.page, 28, VSpace.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isNotEmpty) ...[
            Text('RECIENTES', style: VText.label(11, color: c.text3)),
            const SizedBox(height: 10),
            for (final q in recent)
              InkWell(
                onTap: () => onPick(q),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: c.text3,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(q, style: VText.ui(15, weight: 600)),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        size: 16,
                        color: c.text3,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 26),
          ],
          Text('PARA EMPEZAR', style: VText.label(11, color: c.text3)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, s) in _suggestions.indexed)
                Pill(
                  onTap: () => onPick(s),
                  child: Text(s, style: VText.ui(14, weight: 600)),
                ).animate().fadeIn(delay: (40 * i).ms, duration: 350.ms),
            ],
          ),
        ],
      ),
    );
  }
}
