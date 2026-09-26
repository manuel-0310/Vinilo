import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../services/user_repo.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/search_text.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/line_field.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';

/// Elegir hasta tres discos favoritos de entre los que la persona calificó
/// (con buscador). Devuelve la selección en orden, o null si se cierra.
Future<List<Album>?> showFavoritesPicker(
  BuildContext context, {
  required List<RatingEntry> ratings,
  required List<Album> initial,
}) {
  return showVSheet<List<Album>>(
    context,
    (_) => _FavoritesPicker(ratings: ratings, initial: initial),
  );
}

/// Buscar artistas en Spotify y elegir hasta tres.
Future<List<Artist>?> showArtistsPicker(
  BuildContext context, {
  required List<Artist> initial,
}) {
  return showVSheet<List<Artist>>(context, (_) => _ArtistPicker(initial: initial));
}

/// "1/3" en énfasis, a la derecha del título.
class _Counter extends StatelessWidget {
  const _Counter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Text(
      '$count/${UserRepo.maxFavorites}',
      style: VText.display(28, weight: 700, height: 1, tracking: 0, color: c.accentText),
    );
  }
}

/// Número de orden sobre lo elegido: cuadro de énfasis con la cifra en mono.
class _OrderBadge extends StatelessWidget {
  const _OrderBadge(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      color: c.accent,
      child: Text(
        '$number',
        style: VText.mono(11, weight: 600, tracking: 0, color: c.onAccent),
      ),
    );
  }
}

class _FavoritesPicker extends StatefulWidget {
  const _FavoritesPicker({required this.ratings, required this.initial});

  final List<RatingEntry> ratings;
  final List<Album> initial;

  @override
  State<_FavoritesPicker> createState() => _FavoritesPickerState();
}

class _FavoritesPickerState extends State<_FavoritesPicker> {
  static const int _max = UserRepo.maxFavorites;
  late final List<Album> _selected = [...widget.initial.take(_max)];

  /// Filtra la cuadrícula por disco o artista, sin tildes ni mayúsculas. La
  /// selección no cambia al filtrar.
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(Album album) {
    final index = _selected.indexWhere((a) => a.id == album.id);
    setState(() {
      if (index >= 0) {
        _selected.removeAt(index);
      } else if (_selected.length < _max) {
        HapticFeedback.selectionClick();
        _selected.add(album);
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final albums = <String, Album>{};
    for (final r in widget.ratings) {
      albums.putIfAbsent(r.albumId, () => r.album);
    }
    final list = albums.values.where((a) => albumMatches(a, _query)).toList();
    return SheetScaffold(
      title: l.favoritesPickerTitle,
      subtitle: l.favoritesPickerHint,
      trailing: _Counter(count: _selected.length),
      height: 0.85,
      scrollable: false,
      footer: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: VPrimaryButton.accent(
          key: const ValueKey('favorites-save'),
          label: l.favoritesSave,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
            child: LineField(
              fieldKey: const ValueKey('favorites-search'),
              controller: _search,
              hint: l.favoritesSearchHint,
              leading: VIconView(VIcon.search, size: 18, color: c.ink),
              fontSize: 15,
              padding: const EdgeInsets.symmetric(vertical: 10),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
                    child: Text(
                      l.favoritesNoMatch(_query.trim()),
                      key: const ValueKey('favorites-no-match'),
                      style: VText.ui(14, color: c.ink2, height: 1.45),
                    ),
                  )
                : GridView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final album = list[i];
                      final index = _selected.indexWhere((a) => a.id == album.id);
                      final selected = index >= 0;
                      return GestureDetector(
                        key: ValueKey('fav-option-$i'),
                        onTap: () => _toggle(album),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: selected || _selected.length < _max ? 1 : 0.4,
                              child: AlbumCover(url: album.smallCover),
                            ),
                            if (selected) ...[
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: c.accentText, width: 2),
                                ),
                              ),
                              Positioned(top: 6, right: 6, child: _OrderBadge(index + 1)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArtistPicker extends StatefulWidget {
  const _ArtistPicker({required this.initial});

  final List<Artist> initial;

  @override
  State<_ArtistPicker> createState() => _ArtistPickerState();
}

class _ArtistPickerState extends State<_ArtistPicker> {
  static const int _max = UserRepo.maxFavorites;
  late final List<Artist> _selected = [...widget.initial.take(_max)];
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  List<Artist>? _results;
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _requestId++;
      setState(() {
        _results = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () => _search(q));
  }

  Future<void> _search(String q) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ServicesScope.of(context).spotify.searchArtists(q);
      if (id != _requestId || !mounted) return;
      setState(() {
        _results = results;
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

  void _toggle(Artist artist) {
    final index = _selected.indexWhere((a) => a.id == artist.id);
    setState(() {
      if (index >= 0) {
        _selected.removeAt(index);
      } else if (_selected.length < _max) {
        HapticFeedback.selectionClick();
        _selected.add(artist);
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final results = _results;

    final Widget body;
    if (_error != null) {
      body = VEmptyState(
        title: l.spotifyNoResponse,
        message: describeError(_error, l),
        action: VSecondaryButton(
          label: l.retry,
          center: true,
          onPressed: () => _search(_controller.text.trim()),
        ),
      );
    } else if (_loading && results == null) {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
        itemCount: 5,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              VSkeleton(width: 44, height: 44, circle: true),
              SizedBox(width: 12),
              Expanded(child: VSkeleton(height: 16)),
            ],
          ),
        ),
      );
    } else if (results == null) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
        child: Text(l.artistsPrompt, style: VText.ui(14, color: c.ink2, height: 1.45)),
      );
    } else if (results.isEmpty) {
      body = VEmptyState(title: l.searchNothingTitle, message: l.addNothingBody);
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: results.length,
        itemBuilder: (context, i) {
          final a = results[i];
          final index = _selected.indexWhere((x) => x.id == a.id);
          return _ArtistResultRow(
            key: ValueKey('artist-result-$i'),
            artist: a,
            order: index >= 0 ? index + 1 : null,
            dimmed: index < 0 && _selected.length >= _max,
            onTap: () => _toggle(a),
          );
        },
      );
    }

    return SheetScaffold(
      title: l.artistsPickerTitle,
      subtitle: l.artistsPickerHint,
      trailing: _Counter(count: _selected.length),
      height: 0.85,
      scrollable: false,
      footer: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: VPrimaryButton.accent(
          key: const ValueKey('artists-save'),
          label: l.artistsSave,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
            child: LineField(
              fieldKey: const ValueKey('artist-search'),
              controller: _controller,
              autofocus: true,
              hint: l.artistsSearchHint,
              leading: VIconView(VIcon.search, size: 18, color: c.ink),
              fontSize: 15,
              padding: const EdgeInsets.symmetric(vertical: 10),
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
            ),
          ),
          if (_selected.isNotEmpty)
            SizedBox(
              height: 12 + 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
                itemCount: _selected.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final a = _selected[i];
                  return Pressable(
                    key: ValueKey('artist-selected-$i'),
                    onTap: () => _toggle(a),
                    builder: (context, pressed) => Container(
                      padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
                      decoration: BoxDecoration(border: Border.all(color: pressed ? c.ink : c.accentText)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ArtistAvatar(artist: a, size: 24),
                          const SizedBox(width: 8),
                          Text(a.name, style: VText.ui(13, weight: 600, color: c.accentText)),
                          const SizedBox(width: 8),
                          VIconView(VIcon.close, size: 11, color: c.accentText),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Un artista encontrado: foto de 44, nombre y, a la derecha, su número de
/// orden si ya se eligió o un + con borde.
class _ArtistResultRow extends StatelessWidget {
  const _ArtistResultRow({
    super.key,
    required this.artist,
    required this.order,
    required this.dimmed,
    required this.onTap,
  });

  final Artist artist;
  final int? order;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final selected = order != null;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dimmed ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 10),
          decoration: BoxDecoration(
            color: pressed ? c.inkA(0.04) : null,
            border: Border(bottom: BorderSide(color: c.lineSoft)),
          ),
          child: Row(
            children: [
              ArtistAvatar(artist: artist, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.ui(15, weight: 600, color: selected ? c.accentText : c.ink),
                ),
              ),
              const SizedBox(width: 12),
              if (selected)
                _OrderBadge(order!)
              else
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: c.lineStrong)),
                  child: VIconView(VIcon.plus, size: 13, color: c.ink),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
