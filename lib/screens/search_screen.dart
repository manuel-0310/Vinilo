import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/album_grid.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/line_field.dart';
import '../widgets/person_row.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';
import 'search_all_screen.dart';

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

/// Cuántas búsquedas recientes se muestran (se guardan hasta 8).
const _recentShown = 4;

/// Buscar: "Buscar" en 56, el campo con la lupa y, sin texto, "Recientes"
/// (tocar una la vuelve a buscar) y "Para empezar". Con texto, Personas (si
/// alguien coincide), Artistas y Álbumes, cada uno con "Ver todos".
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
  Object? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
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
    setState(() {}); // Aparece la ×.
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
    final l = context.l10n;
    final me = CurrentUser.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final people = _people ?? const <PersonInfo>[];
    final artists = _artists ?? const <Artist>[];

    return Scaffold(
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 18, VSpace.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.searchTitle,
                    style: VText.display(56, weight: 800, height: 0.88, tracking: 0),
                  ),
                  const SizedBox(height: 18),
                  LineField(
                    fieldKey: const ValueKey('search-field'),
                    controller: _controller,
                    focusNode: _focus,
                    hint: l.searchHint,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    leading: VIconView(VIcon.search, size: 20, color: c.ink),
                    trailing: _controller.text.isEmpty
                        ? null
                        : Pressable(
                            key: const ValueKey('search-clear'),
                            onTap: _clear,
                            builder: (context, pressed) => Semantics(
                              label: l.searchClear,
                              button: true,
                              child: Opacity(
                                opacity: pressed ? 0.5 : 1,
                                child: VIconView(VIcon.close, size: 16, color: c.inkA(0.6)),
                              ),
                            ),
                          ),
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                  ),
                ],
              ),
            ),
          ),
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: _Suggestions(
                recent: me.recentSearches.take(_recentShown).toList(),
                onPick: _submit,
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: VEmptyState(
                title: l.spotifyNoResponse,
                message: describeError(_error, l),
                padding: const EdgeInsets.fromLTRB(VSpace.page, 26, VSpace.page, 24),
                action: VSecondaryButton(
                  key: const ValueKey('search-retry'),
                  label: l.retry,
                  onPressed: () => _search(_query),
                ),
              ),
            )
          else if (_loading && _page == null)
            const SliverPadding(
              padding: EdgeInsets.only(top: 22),
              sliver: AlbumGridSkeleton(),
            )
          else if (_page != null &&
              _page!.items.isEmpty &&
              artists.isEmpty &&
              people.isEmpty)
            SliverToBoxAdapter(
              child: VEmptyState(
                title: l.searchNothingTitle,
                message: _query.startsWith('@') ? l.searchNoUsername : l.searchNothingBody,
                padding: const EdgeInsets.fromLTRB(VSpace.page, 26, VSpace.page, 24),
              ),
            )
          else if (_page != null) ...[
            if (people.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VSectionHeader(
                      l.searchPeople,
                      line: false,
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 22, VSpace.page, 10),
                    ),
                    for (final (i, p) in people.indexed)
                      PersonRow(
                        key: ValueKey('person-hit-$i'),
                        person: p,
                        trailing: const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            if (artists.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VSectionHeader(
                      l.searchArtists,
                      line: false,
                      padding: EdgeInsets.fromLTRB(VSpace.page, people.isEmpty ? 22 : 26, VSpace.page, 10),
                      action: l.seeAllPlural,
                      onAction: () => openSearchAll(context, query: _query, kind: SearchAllKind.artists),
                      actionKey: const ValueKey('artists-all'),
                    ),
                    _ArtistStrip(artists: artists),
                  ],
                ),
              ),
            if (_page!.items.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: VSectionHeader(
                  l.searchAlbums,
                  line: false,
                  padding: EdgeInsets.fromLTRB(
                    VSpace.page,
                    artists.isEmpty && people.isEmpty ? 22 : 26,
                    VSpace.page,
                    10,
                  ),
                  action: l.seeAllPlural,
                  onAction: () => openSearchAll(context, query: _query, kind: SearchAllKind.albums),
                  actionKey: const ValueKey('albums-all'),
                ),
              ),
              AlbumGrid(
                albums: _page!.items,
                heroPrefix: 'search',
                keyPrefix: 'result',
                onOpen: (album, heroTag) {
                  _remember(_query);
                  openAlbum(context, album, heroTag: heroTag);
                },
              ),
            ],
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: VSpace.tabBarClearance),
          ),
        ],
      ),
    );
  }
}

/// Fila horizontal de artistas encontrados: círculo de 80 y el nombre
/// (13/600) centrado debajo.
class _ArtistStrip extends StatelessWidget {
  const _ArtistStrip({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Círculo, 8 de aire y dos líneas de 13 × 1,2.
      height: 80 + 8 + 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
        itemCount: artists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final a = artists[i];
          return GestureDetector(
            key: ValueKey('artist-hit-$i'),
            onTap: () => openArtist(context, a),
            child: SizedBox(
              width: 80,
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
            ),
          );
        },
      ),
    );
  }
}

/// Sin texto: "Recientes" (filas de 17 con ↖) y "Para empezar" (nombres
/// en 30 condensados, separados por "/").
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.recent, required this.onPick});

  final List<String> recent;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final big = VText.display(30, weight: 700, stretch: 70, height: 1.15, tracking: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 26, VSpace.page, 8),
            child: VMono(l.searchRecent),
          ),
          for (final (i, q) in recent.indexed)
            Pressable(
              key: ValueKey('recent-$i'),
              onTap: () => onPick(q),
              builder: (context, pressed) => Container(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
                decoration: BoxDecoration(
                  color: pressed ? c.inkA(0.04) : null,
                  border: Border(
                    top: BorderSide(color: c.lineSoft),
                    bottom: i == recent.length - 1
                        ? BorderSide(color: c.lineSoft)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(17),
                      ),
                    ),
                    const SizedBox(width: 12),
                    VIconView(VIcon.arrowUpLeft, size: 14, color: c.placeholder),
                  ],
                ),
              ),
            ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(VSpace.page, recent.isEmpty ? 26 : 30, VSpace.page, 10),
          child: VMono(l.searchSuggestions),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
          child: Wrap(
            spacing: 10,
            runSpacing: 2,
            children: [
              for (final (i, s) in _suggestions.indexed) ...[
                if (i > 0) Text('/', style: big.copyWith(color: c.inkA(0.3))),
                Pressable(
                  key: ValueKey('suggestion-$i'),
                  onTap: () => onPick(s),
                  builder: (context, pressed) => Text(
                    s,
                    style: big.copyWith(color: pressed ? c.accent : c.ink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
