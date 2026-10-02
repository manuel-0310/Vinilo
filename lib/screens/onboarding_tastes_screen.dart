import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/onboarding.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../services/user_repo.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/album_cover.dart';
import '../widgets/line_field.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';

/// Paso 1 de 2 del onboarding, obligatorio: "Elige 3 discos que te
/// encanten". Un buscador, los filtros por género y una cuadrícula de 3
/// columnas; tocar una portada la elige (contorno de énfasis y su número de
/// orden) y tocarla otra vez la quita. Con 3 o más se enciende "Continuar":
/// los tres primeros quedan de favoritos y todos alimentan las sugerencias
/// del paso 2.
class OnboardingTastesScreen extends StatefulWidget {
  const OnboardingTastesScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<OnboardingTastesScreen> createState() => _OnboardingTastesScreenState();
}

class _OnboardingTastesScreenState extends State<OnboardingTastesScreen> {
  TasteGenre _genre = TasteGenre.popular;

  /// Lo que ya se cargó de cada filtro (un fallo no se guarda: se reintenta).
  final Map<TasteGenre, Future<List<Album>>> _byGenre = {};

  List<Album> _picked = const [];

  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<List<Album>>? _results;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<List<Album>> _albumsFor(TasteGenre genre) =>
      _byGenre.putIfAbsent(genre, () => _fetch(ServicesScope.of(context), genre));

  /// Los discos de un filtro. "Populares" son los más calificados de la
  /// comunidad, completados con la selección; los demás, la selección del
  /// género buscada disco por disco.
  static Future<List<Album>> _fetch(Services services, TasteGenre genre) async {
    Object? failure;
    Future<Album?> find(TasteSeed seed) async {
      try {
        final page = await services.spotify.search(seedQuery(seed));
        return pickSeedResult(seed, page.items);
      } catch (e) {
        failure = e;
        return null;
      }
    }

    var community = const <Album>[];
    if (genre == TasteGenre.popular) {
      try {
        final stats = await services.ratings.mostRated(limit: tasteGridSize);
        community = [for (final s in stats) s.album];
      } catch (_) {
        // Sin la comunidad, queda la selección.
      }
      if (community.length >= tasteGridSize) return community;
    }
    final found = await Future.wait(tasteSeeds[genre]!.map(find));
    final albums = mergeTasteAlbums(community, found);
    if (albums.isEmpty) throw failure ?? StateError('sin discos');
    return albums;
  }

  void _retry() {
    setState(() {
      if (_query.isEmpty) {
        _byGenre.remove(_genre);
      } else {
        _results = _searchFor(_query);
      }
    });
  }

  Future<List<Album>> _searchFor(String q) async =>
      (await ServicesScope.of(context).spotify.search(q)).items;

  void _onSearch(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() {
        _query = q;
        _results = _searchFor(q);
      });
    });
  }

  void _toggle(Album album) {
    final next = toggleTaste(_picked, album, max: UserRepo.maxTastes);
    if (identical(next, _picked)) {
      // Ya hay el máximo: no entra otro.
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _picked = next);
  }

  Future<void> _continue() async {
    if (_busy || _picked.length < tastesRequired) return;
    final users = ServicesScope.of(context).users;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      // El perfil pasa al paso 2 y `main.dart` cambia de pantalla.
      await users.saveTastes(widget.profile.uid, _picked);
      HapticFeedback.mediumImpact();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotSave(describeError(e, l)))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final searching = _query.isNotEmpty;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomPad = keyboard ? 14.0 : math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    final count = _picked.length;
    final ready = count >= tastesRequired;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: c.line)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [VMono(l.onboardStep1), VMono(l.onboardStep1Label)],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l.onboardTastesTitle,
                            key: const ValueKey('tastes-title'),
                            style: VText.display(52, weight: 800, height: 0.88, tracking: 0),
                          ),
                          const SizedBox(height: 10),
                          Text(l.onboardTastesBody, style: VText.ui(15, height: 1.45, color: c.ink2)),
                          const SizedBox(height: 16),
                          LineField(
                            fieldKey: const ValueKey('tastes-search'),
                            controller: _search,
                            hint: l.onboardSearchHint,
                            fontSize: 15,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textInputAction: TextInputAction.search,
                            autocorrect: false,
                            leading: VMono(l.listsSearchLabel),
                            leadingGap: 10,
                            onChanged: _onSearch,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Los filtros llevan 12 de aire arriba y abajo para el
                  // toque: 14 y 16 del prototipo, menos esos 12.
                  if (!searching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: VTextFilters(
                          labels: [for (final g in TasteGenre.values) g.label(l)],
                          keys: [for (final g in TasteGenre.values) 'taste-genre-${g.name}'],
                          selected: _genre.index,
                          onChanged: (i) => setState(() => _genre = TasteGenre.values[i]),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(VSpace.page, searching ? 16 : 4, VSpace.page, 24),
                    sliver: SliverToBoxAdapter(
                      child: FutureBuilder<List<Album>>(
                        // Con otra llave por filtro o búsqueda, no se ve un
                        // instante la cuadrícula anterior.
                        key: ValueKey(searching ? 'q:$_query' : 'g:${_genre.name}'),
                        future: searching ? _results : _albumsFor(_genre),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return _Problem(
                              text: '${l.onboardTastesError} ${describeError(snap.error, l)}',
                              onRetry: _retry,
                            );
                          }
                          final albums = snap.data;
                          if (albums == null || snap.connectionState != ConnectionState.done) {
                            return const _GridSkeleton();
                          }
                          if (albums.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                l.onboardNoResults(_query),
                                key: const ValueKey('tastes-empty'),
                                style: VText.ui(15, height: 1.45, color: c.ink2),
                              ),
                            );
                          }
                          return TasteGrid(albums: albums, picked: _picked, onToggle: _toggle);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, bottomPad),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < tastesRequired; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 4,
                          color: i < count ? c.accent : c.line,
                        ),
                      ],
                      const Spacer(),
                      VMono(
                        ready ? l.onboardPickedReady(count) : l.onboardPicked(count),
                        key: const ValueKey('tastes-count'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  VPrimaryButton.accent(
                    key: const ValueKey('tastes-continue'),
                    label: l.onboardContinue,
                    busy: _busy,
                    mutedWhenDisabled: true,
                    onPressed: ready ? _continue : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La cuadrícula de 3 columnas con 8 de separación: cada disco con su
/// insignia y, si está elegido, su contorno y su número de orden.
class TasteGrid extends StatelessWidget {
  const TasteGrid({super.key, required this.albums, required this.picked, required this.onToggle});

  final List<Album> albums;
  final List<Album> picked;
  final ValueChanged<Album> onToggle;

  static const int columns = 3;
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final rows = (albums.length + columns - 1) ~/ columns;
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : gap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var k = 0; k < columns; k++) ...[
                  if (k > 0) const SizedBox(width: gap),
                  Expanded(
                    child: r * columns + k < albums.length
                        ? _tile(r * columns + k)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _tile(int i) {
    final album = albums[i];
    final order = picked.indexWhere((a) => a.id == album.id);
    return _TasteTile(
      key: ValueKey('taste-$i'),
      album: album,
      order: order < 0 ? null : order + 1,
      onTap: () => onToggle(album),
    );
  }
}

/// Un disco para elegir: la portada con su insignia arriba a la derecha (un
/// cuadro vacío, o el número de orden sobre el énfasis si está elegido, con
/// un contorno de 3 alrededor de la portada), el título y el artista.
class _TasteTile extends StatelessWidget {
  const _TasteTile({super.key, required this.album, required this.order, required this.onTap});

  final Album album;

  /// En qué puesto se eligió (1, 2, 3…); null si no está elegido.
  final int? order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final on = order != null;
    // La insignia vacía va sobre una foto: oscura y con borde claro en los
    // dos temas.
    const overPhoto = ViniloPalette.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AlbumCover(url: album.smallCover),
              if (on)
                // `outline: 3px` con `outline-offset: -2px`: 2 hacia dentro
                // y 1 hacia fuera del borde de la portada.
                Positioned(
                  left: -1,
                  top: -1,
                  right: -1,
                  bottom: -1,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(border: Border.all(color: c.accent, width: 3)),
                    ),
                  ),
                ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.accent : overPhoto.bg.withValues(alpha: 0.45),
                    border: on ? null : Border.all(color: overPhoto.ink.withValues(alpha: 0.6)),
                  ),
                  child: on
                      ? Text('$order', style: VText.mono(11, weight: 600, tracking: 0, color: c.onAccent))
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VText.ui(13, weight: 600),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VText.ui(11.5, color: c.inactive),
          ),
        ],
      ),
    );
  }
}

/// Mientras cargan los discos: la misma cuadrícula en bloques, con un solo
/// brillo.
class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return VShimmer(
      child: Column(
        key: const ValueKey('tastes-loading'),
        children: [
          for (var r = 0; r < 3; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == 2 ? 0 : TasteGrid.gap),
              child: const Row(
                children: [
                  Expanded(child: _TileSkeleton()),
                  SizedBox(width: TasteGrid.gap),
                  Expanded(child: _TileSkeleton()),
                  SizedBox(width: TasteGrid.gap),
                  Expanded(child: _TileSkeleton()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1, child: VSkeleton()),
        SizedBox(height: 8),
        FractionallySizedBox(widthFactor: 0.8, child: VSkeleton(height: 10)),
        SizedBox(height: 6),
        FractionallySizedBox(widthFactor: 0.5, child: VSkeleton(height: 8, soft: true)),
        SizedBox(height: 5),
      ],
    );
  }
}

/// No cargaron los discos: qué pasó y "Reintentar".
class _Problem extends StatelessWidget {
  const _Problem({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: VText.ui(14, height: 1.45, color: c.ink2)),
          const SizedBox(height: 14),
          VSecondaryButton(
            key: const ValueKey('tastes-retry'),
            label: context.l10n.retry,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
