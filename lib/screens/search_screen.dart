import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/search_text.dart';
import '../util/tab_reselect.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_grid.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/line_field.dart';
import '../widgets/person_row.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import '../widgets/v_states.dart';
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
  const SearchScreen({super.key, this.reselect});

  /// Volver a tocar "Buscar" en la barra: sube hasta arriba; ya arriba,
  /// borra la búsqueda y, con el campo vacío, abre el teclado.
  final TabReselect? reselect;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Timer? _debounce;
  int _requestId = 0;

  String _query = '';
  AlbumPage? _page;
  List<Artist>? _artists;
  List<PersonInfo>? _people;
  bool _loading = false;
  Object? _error;

  /// "Reintentar" desde "Sin conexión" o "Se rayó el disco": el aviso se
  /// queda con su spinner hasta que llega la respuesta.
  bool _retrying = false;

  /// Sin resultados: discos de búsquedas parecidas ("¿Quisiste decir?").
  List<Album>? _didYouMean;

  /// Ya se pidió agregar el disco que no se encontró.
  bool _requested = false;
  late final TapGestureRecognizer _requestTap = TapGestureRecognizer()..onTap = _requestAlbum;

  @override
  void initState() {
    super.initState();
    widget.reselect?.addListener(_onReselect);
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reselect != widget.reselect) {
      oldWidget.reselect?.removeListener(_onReselect);
      widget.reselect?.addListener(_onReselect);
    }
  }

  @override
  void dispose() {
    widget.reselect?.removeListener(_onReselect);
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    _requestTap.dispose();
    super.dispose();
  }

  void _onReselect() {
    switch (searchReselect(atTop: isAtTop(_scroll), hasText: _controller.text.isNotEmpty)) {
      case SearchReselect.scrollTop:
        scrollToTop(_scroll);
      case SearchReselect.clear:
        _debounce?.cancel();
        _controller.clear();
        _onChanged('');
        _focus.unfocus();
      case SearchReselect.focus:
        _focus.requestFocus();
    }
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
        _didYouMean = null;
        _requested = false;
      });
      return;
    }
    setState(() {}); // Aparece la ×.
    _debounce = Timer(const Duration(milliseconds: 380), () => _search(q));
  }

  /// Busca. Con `keepError` (los "Reintentar"), el aviso de error se queda
  /// hasta que llega la respuesta.
  Future<void> _search(String q, {bool keepError = false}) async {
    if (q.isEmpty) return;
    final id = ++_requestId;
    setState(() {
      if (q != _query) {
        _didYouMean = null;
        _requested = false;
      }
      _query = q;
      _loading = true;
      if (!keepError) _error = null;
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
        _error = null;
      });
      if (result.items.isEmpty && found.isEmpty && foundPeople.isEmpty) {
        unawaited(_suggest(q, id));
      }
    } catch (e) {
      if (id != _requestId || !mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// "¿Quisiste decir?": prueba búsquedas parecidas (`didYouMeanQueries`)
  /// hasta juntar tres discos.
  Future<void> _suggest(String q, int id) async {
    final spotify = ServicesScope.of(context).spotify;
    final found = <Album>[];
    for (final candidate in didYouMeanQueries(q)) {
      try {
        final page = await spotify.search(candidate);
        for (final album in page.items) {
          if (found.length < 3 && !found.any((a) => a.id == album.id)) found.add(album);
        }
      } catch (_) {
        // Una que falla no impide las demás.
      }
      if (found.length >= 3 || id != _requestId || !mounted) break;
    }
    if (id != _requestId || !mounted) return;
    setState(() => _didYouMean = found);
  }

  /// "Reintentar" desde un error: vuelve a comprobar la conexión si era
  /// eso y repite la búsqueda.
  Future<void> _retry() async {
    if (_retrying) return;
    final error = _error;
    setState(() => _retrying = true);
    if (isOfflineError(error)) await ServicesScope.of(context).connectivity.check();
    await _search(_query, keepError: true);
    if (mounted) setState(() => _retrying = false);
  }

  /// "Pídenos que lo agreguemos": queda anotado en `requests/` (sin
  /// esperar: si no hay conexión, sube cuando vuelva).
  void _requestAlbum() {
    final me = CurrentUser.maybeOf(context);
    if (me == null || _requested || _query.isEmpty) return;
    unawaited(
      ServicesScope.of(context)
          .support
          .requestAlbum(uid: me.uid, query: _query)
          .catchError((Object _) {}),
    );
    setState(() => _requested = true);
  }

  void _openSaved() {
    final me = CurrentUser.of(context);
    openDiary(context, uid: me.uid, name: me.name, isMe: true, initial: const []);
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
    final people = Moderation.of(context).people(_people ?? const <PersonInfo>[]);
    final artists = _artists ?? const <Artist>[];

    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
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
          else if (_error != null && isOfflineError(_error))
            SliverFillRemaining(
              hasScrollBody: false,
              child: OfflineState(
                checking: _retrying,
                onRetry: _retry,
                onSaved: _openSaved,
                padding: const EdgeInsets.fromLTRB(VSpace.page, 26, VSpace.page, 24),
              ),
            )
          else if (_error != null && isServerError(_error))
            SliverFillRemaining(
              hasScrollBody: false,
              child: ServerErrorState(
                error: _error,
                retrying: _retrying,
                onRetry: _retry,
                where: 'search: $_query',
                padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 24),
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
                  busy: _retrying,
                  onPressed: _retry,
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
              child: _query.startsWith('@')
                  ? VEmptyState(
                      title: l.searchNothingTitle,
                      message: l.searchNoUsername,
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 26, VSpace.page, 24),
                    )
                  : _NotFound(
                      query: _query,
                      suggestions: _didYouMean,
                      requested: _requested,
                      requestTap: _requestTap,
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

/// Sin resultados (prototipo "Vacío · búsqueda"): "0 resultados", "No
/// encontramos “…”", qué probar, "¿Quisiste decir?" con hasta tres discos
/// de búsquedas parecidas y "¿Falta un disco en Vinilo? Pídenos que lo
/// agreguemos".
class _NotFound extends StatelessWidget {
  const _NotFound({
    required this.query,
    required this.suggestions,
    required this.requested,
    required this.requestTap,
  });

  final String query;
  final List<Album>? suggestions;
  final bool requested;
  final TapGestureRecognizer requestTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final found = suggestions ?? const <Album>[];
    return Padding(
      key: const ValueKey('search-not-found'),
      padding: const EdgeInsets.fromLTRB(VSpace.page, 36, VSpace.page, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VMono(l.searchZeroResults),
          const SizedBox(height: 8),
          Text(
            l.searchNotFound(query),
            style: VText.display(30, weight: 700, stretch: 70, height: 1.02, tracking: 0),
          ),
          const SizedBox(height: 10),
          Text(l.searchNotFoundBody, style: VText.ui(15, height: 1.45, color: c.ink2)),
          if (found.isNotEmpty) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: VMono(l.searchDidYouMean),
            ),
            for (final (i, album) in found.indexed)
              Pressable(
                key: ValueKey('did-you-mean-$i'),
                onTap: () => openAlbum(context, album, heroTag: 'dym-${album.id}'),
                builder: (context, pressed) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: pressed ? c.inkA(0.04) : null,
                    border: Border(bottom: BorderSide(color: c.lineSoft)),
                  ),
                  child: Row(
                    children: [
                      AlbumCover(url: album.smallCover, size: 52, heroTag: 'dym-${album.id}'),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(16, weight: 600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              album.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(13, color: c.ink3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('→', style: VText.ui(16, color: c.ink4)),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 22),
          if (requested)
            Text(
              l.searchRequestSent(query),
              key: const ValueKey('search-request-sent'),
              style: VText.ui(14, height: 1.45, color: c.ink2),
            )
          else
            Text.rich(
              key: const ValueKey('search-request'),
              TextSpan(
                children: [
                  TextSpan(text: l.searchMissingLead),
                  TextSpan(
                    text: l.searchMissingAction,
                    recognizer: requestTap,
                    style: TextStyle(
                      color: c.ink,
                      decoration: TextDecoration.underline,
                      decorationColor: c.ink,
                    ),
                  ),
                ],
              ),
              style: VText.ui(14, height: 1.45, color: c.ink2),
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
                    style: big.copyWith(color: pressed ? c.accentText : c.ink),
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
