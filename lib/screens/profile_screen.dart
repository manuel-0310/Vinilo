import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../services/user_repo.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/search_text.dart';
import '../util/share_links.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/diary_row.dart';
import '../widgets/follow_button.dart';
import '../widgets/histogram.dart';
import '../widgets/list_row_tile.dart';
import '../widgets/misc.dart';
import '../widgets/share_button.dart';
import '../widgets/user_avatar.dart';
import 'list_form_sheet.dart';
import 'routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.uid,
    required this.isMe,
    this.standalone = false,
  });

  final String uid;
  final bool isMe;

  /// True cuando se abre como ruta propia (perfil de otra persona).
  final bool standalone;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Las dos secciones del perfil: favoritos, gráfica y diario, o listas.
enum _ProfileSection { perfil, listas }

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileSection _section = _ProfileSection.perfil;

  // Pestaña "Listas": se conservan al ir y volver de "Perfil".
  ListQuery _listQuery = const ListQuery();
  bool _showSavedLists = false;
  final _listSearch = TextEditingController();

  @override
  void dispose() {
    _listSearch.dispose();
    super.dispose();
  }
  Stream<UserProfile?>? _profile;
  Stream<List<RatingEntry>>? _ratings;
  Stream<List<MusicList>>? _lists;
  Stream<List<MusicList>>? _saved;
  Future<List<RatingEntry>>? _mineForAffinity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ratings != null) return;
    final services = ServicesScope.of(context);
    _ratings = services.ratings.userRatings(widget.uid);
    _lists = services.lists.ownedBy(widget.uid);
    if (widget.isMe) _saved = services.lists.savedBy(widget.uid);
    if (!widget.isMe) {
      _profile = services.users.watch(widget.uid);
      final me = CurrentUser.maybeOf(context);
      if (me != null) {
        _mineForAffinity = services.ratings.fetchUserRatings(me.uid);
      }
    }
  }

  Future<void> _pickFavorites(
    UserProfile profile,
    List<RatingEntry> ratings,
  ) async {
    final services = ServicesScope.of(context);
    final picked = await showModalBottomSheet<List<Album>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FavoritesPicker(
        ratings: ratings,
        initial: profile.favorites.take(UserRepo.maxFavorites).toList(),
      ),
    );
    if (picked == null) return;
    await services.users.setFavorites(profile.uid, picked);
  }

  Future<void> _newList(UserProfile profile) async {
    final draft = await showListForm(context);
    if (draft == null || !mounted) return;
    try {
      final list = await ServicesScope.of(context).lists.create(
            owner: profile,
            name: draft.name,
            description: draft.description,
            kind: draft.kind,
            itemType: draft.itemType,
          );
      if (mounted) openList(context, listId: list.id, initial: list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.listCreateFailed(describeError(e, context.l10n)))),
      );
    }
  }

  Future<void> _pickArtists(UserProfile profile) async {
    final services = ServicesScope.of(context);
    final picked = await showModalBottomSheet<List<Artist>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ArtistPicker(initial: profile.favoriteArtists),
    );
    if (picked == null) return;
    await services.users.setFavoriteArtists(profile.uid, picked);
  }

  @override
  Widget build(BuildContext context) {
    final me = CurrentUser.maybeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;

    Widget body(UserProfile? profile) {
      if (profile == null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: topPad),
            child: const CircularProgressIndicator(),
          ),
        );
      }
      return StreamBuilder<List<RatingEntry>>(
        stream: _ratings,
        builder: (context, snap) {
          final ratings = snap.data;
          return _ProfileBody(
            profile: profile,
            ratings: ratings,
            lists: _lists,
            saved: _saved,
            isMe: widget.isMe,
            standalone: widget.standalone,
            section: _section,
            onSection: (section) => setState(() => _section = section),
            listSearch: _listSearch,
            listQuery: _listQuery,
            onListQuery: (q) => setState(() => _listQuery = q),
            showSavedLists: _showSavedLists,
            onShowSavedLists: (v) => setState(() => _showSavedLists = v),
            mineForAffinity: _mineForAffinity,
            onNewList: () => _newList(profile),
            onPickFavorites: ratings == null
                ? null
                : () => _pickFavorites(profile, ratings),
            onPickArtists: () => _pickArtists(profile),
          );
        },
      );
    }

    if (widget.isMe) {
      return Scaffold(body: body(me));
    }
    return Scaffold(
      body: StreamBuilder<UserProfile?>(
        stream: _profile,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return body(null);
          }
          final profile = snap.data;
          if (profile == null) {
            return Stack(
              children: [
                Center(
                  child: EmptyState(
                    title: context.l10n.profileNotFound,
                    message: context.l10n.profileNotFoundBody,
                  ),
                ),
                Positioned(
                  top: topPad + 8,
                  left: 16,
                  child: GlassIconButton(
                    key: const ValueKey('back'),
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            );
          }
          return body(profile);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.ratings,
    required this.lists,
    required this.saved,
    required this.isMe,
    required this.standalone,
    required this.section,
    required this.onSection,
    required this.listSearch,
    required this.listQuery,
    required this.onListQuery,
    required this.showSavedLists,
    required this.onShowSavedLists,
    required this.mineForAffinity,
    required this.onNewList,
    required this.onPickFavorites,
    required this.onPickArtists,
  });

  final UserProfile profile;
  final List<RatingEntry>? ratings;
  final Stream<List<MusicList>>? lists;

  /// Listas guardadas (solo en el perfil propio).
  final Stream<List<MusicList>>? saved;
  final bool isMe;
  final bool standalone;
  final _ProfileSection section;
  final ValueChanged<_ProfileSection> onSection;
  final TextEditingController listSearch;
  final ListQuery listQuery;
  final ValueChanged<ListQuery> onListQuery;
  final bool showSavedLists;
  final ValueChanged<bool> onShowSavedLists;
  final Future<List<RatingEntry>>? mineForAffinity;
  final VoidCallback onNewList;
  final VoidCallback? onPickFavorites;
  final VoidCallback onPickArtists;

  static const int _diaryPreview = 5;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final list = ratings ?? const <RatingEntry>[];
    final average = list.isEmpty
        ? null
        : list.fold<int>(0, (s, r) => s + r.score) / list.length;
    final hist = {
      for (var i = 1; i <= 10; i++) i: list.where((r) => r.score == i).length,
    };
    final banner = profile.bannerUrl;
    final bannerHeight = topPad + 150;
    final favorites = profile.favorites.take(UserRepo.maxFavorites).toList();
    final artists = profile.favoriteArtists.take(UserRepo.maxFavorites).toList();

    Widget content = Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Encabezado con el fondo dentro (foto o resplandor): así sube con
            // él al hacer scroll y el resto queda sobre el fondo liso.
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (banner != null)
                    Positioned(
                      top: -AmbientGlow.bleed,
                      left: 0,
                      right: 0,
                      height: AmbientGlow.bleed + bannerHeight,
                      child: _Banner(url: banner, color: profile.color, height: bannerHeight),
                    )
                  else
                    Positioned(
                      top: -AmbientGlow.bleed,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AmbientGlow(
                        color: profile.color.withValues(alpha: 0.55),
                        focus: 40,
                      ),
                    ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          VSpace.page,
                          banner != null
                              ? bannerHeight - 39
                              : topPad + (standalone ? 62 : 22),
                          VSpace.page,
                          0,
                        ),
                        child: Row(
                          crossAxisAlignment: banner != null
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.center,
                          children: [
                            UserAvatar(
                              name: profile.name,
                              color: profile.color,
                              url: profile.avatarUrl,
                              size: 78,
                              ring: true,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: banner != null ? 42 : 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: VText.display(34, height: 1),
                                    ),
                                    const SizedBox(height: 5),
                                    if (profile.username != null) ...[
                                      Text(
                                        profile.handle,
                                        key: const ValueKey('profile-handle'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: VText.ui(13, weight: 700, color: c.text2),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: banner != null ? 42 : 0),
                              child: Row(
                                children: [
                                  Builder(
                                    builder: (buttonContext) => _HeaderButton(
                                      key: const ValueKey('share-profile'),
                                      icon: Icons.ios_share_rounded,
                                      tooltip: context.l10n.shareAction,
                                      onTap: () => shareMessage(
                                        buttonContext,
                                        shareProfileMessage(profile, context.l10n, mine: isMe),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isMe)
                                    // Editar el perfil vive dentro de Configuración.
                                    _HeaderButton(
                                      key: const ValueKey('settings'),
                                      icon: Icons.settings_rounded,
                                      tooltip: context.l10n.settingsTitle,
                                      onTap: () => openSettings(context),
                                    )
                                  else
                                    FollowButton(
                                      person: profile.person,
                                      testKey: 'follow-profile',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((profile.bio ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              profile.bio!.trim(),
                              key: const ValueKey('profile-bio'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(14, height: 1.4),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
                        child: _FollowCounts(profile: profile, isMe: isMe),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: c.surface.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: c.line),
                          ),
                          child: Row(
                            children: [
                              _Stat(
                                value: '${list.length}',
                                label: context.l10n.statAlbums(list.length),
                              ),
                              const _StatDivider(),
                              _Stat(
                                value: average == null ? '–' : Score.formatAverage(average, context.l10n.localeName),
                                label: context.l10n.statAverage,
                                color: average == null ? null : c.score(average),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isMe && mineForAffinity != null)
                        _AffinityCard(
                          theirs: list,
                          mine: mineForAffinity!,
                          name: profile.name,
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
            // Dos secciones: "Perfil" (favoritos, gráfica y diario) y
            // "Listas" (las suyas y, en el propio, las guardadas).
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(VSpace.page, 8, VSpace.page, 0),
                child: SectionSwitch(
                  labels: [context.l10n.tabProfile, context.l10n.profileListsTab],
                  keys: const ['profile-section-perfil', 'profile-section-listas'],
                  selected: section.index,
                  onChanged: (i) => onSection(_ProfileSection.values[i]),
                ),
              ),
            ),
            if (section == _ProfileSection.perfil) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    context.l10n.favorites,
                    subtitle: isMe
                        ? context.l10n.favoritesMine
                        : context.l10n.favoritesTheirs,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniHeader(
                          label: context.l10n.favoritesAlbumsLabel,
                          pickKey: 'pick-favorites',
                          onPick: isMe && list.isNotEmpty ? onPickFavorites : null,
                        ),
                        const SizedBox(height: 10),
                        _FavoritesRow(
                          favorites: favorites,
                          uid: profile.uid,
                          onEmptyTap: isMe && list.isNotEmpty ? onPickFavorites : null,
                        ),
                        const SizedBox(height: 20),
                        _MiniHeader(
                          label: context.l10n.favoritesArtistsLabel,
                          pickKey: 'pick-artists',
                          onPick: isMe ? onPickArtists : null,
                        ),
                        const SizedBox(height: 10),
                        _ArtistsRow(
                          artists: artists,
                          onEmptyTap: isMe ? onPickArtists : null,
                        ),
                      ],
                    ),
                  ),
                ),
                if (list.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 28, VSpace.page, 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: ScoreHistogram(hist: hist, height: 64),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    context.l10n.diary,
                    subtitle: ratings == null
                        ? context.l10n.loading
                        : context.l10n.countRatedAlbums(list.length),
                  ),
                ),
                if (ratings == null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    sliver: SliverList.separated(
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) => const Skeleton(height: 60, radius: 14),
                    ),
                  )
                else if (list.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      title: isMe ? context.l10n.diaryEmptyMine : context.l10n.diaryEmptyTheirs,
                      message: isMe
                          ? context.l10n.diaryEmptyMineBody
                          : context.l10n.diaryEmptyTheirsBody(profile.name),
                      labelColor: profile.color,
                    ),
                  )
                else
                  DiaryList(entries: list.take(_diaryPreview).toList()),
                if (list.length > _diaryPreview)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
                      child: Center(
                        child: Pill(
                          key: const ValueKey('diary-more'),
                          onTap: () => openDiary(
                            context,
                            uid: profile.uid,
                            name: profile.name,
                            isMe: isMe,
                            initial: list,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Text(
                            context.l10n.seeMore(list.length - _diaryPreview),
                            style: VText.ui(13, weight: 700),
                          ),
                        ),
                      ),
                    ),
                  ),
            ] else ...[
              SliverToBoxAdapter(
                child: _ListsBrowser(
                  owned: lists,
                  saved: isMe ? saved : null,
                  isMe: isMe,
                  name: profile.name,
                  search: listSearch,
                  query: listQuery,
                  onQuery: onListQuery,
                  showSaved: showSavedLists,
                  onShowSaved: onShowSavedLists,
                  onNewList: onNewList,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: standalone
                    ? MediaQuery.paddingOf(context).bottom + 30
                    : VSpace.tabBarClearance,
              ),
            ),
          ],
        ),
        if (standalone)
          Positioned(
            top: topPad + 8,
            left: 16,
            child: GlassIconButton(
              key: const ValueKey('back'),
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
      ],
    );

    if (banner != null) {
      // Sobre la foto de fondo la barra de estado siempre va clara.
      content = AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: content,
      );
    }
    return content;
  }
}

/// Foto de fondo del perfil: ocupa la parte alta, se funde con el fondo por
/// abajo y lleva un velo arriba para que la hora se lea. La franja superior
/// (la que solo se ve al rebotar el scroll) es del color del perfil.
class _Banner extends StatelessWidget {
  const _Banner({required this.url, required this.color, required this.height});

  final String url;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final band = Color.alphaBlend(color.withValues(alpha: 0.35), c.bg);
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(child: ColoredBox(color: band)),
          SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: band),
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.5],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.bg.withValues(alpha: 0),
                        c.bg,
                      ],
                      stops: const [0.5, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La pestaña "Listas" del perfil: en el propio, "Mías" y "Guardadas"; un
/// buscador (por nombre, descripción o lo que tiene dentro), filtros por tipo
/// (lista o ranking) y contenido (canciones o discos), el orden y un resumen
/// de cuántas se ven.
class _ListsBrowser extends StatelessWidget {
  const _ListsBrowser({
    required this.owned,
    required this.saved,
    required this.isMe,
    required this.name,
    required this.search,
    required this.query,
    required this.onQuery,
    required this.showSaved,
    required this.onShowSaved,
    required this.onNewList,
  });

  final Stream<List<MusicList>>? owned;

  /// Solo en el perfil propio.
  final Stream<List<MusicList>>? saved;
  final bool isMe;
  final String name;
  final TextEditingController search;
  final ListQuery query;
  final ValueChanged<ListQuery> onQuery;
  final bool showSaved;
  final ValueChanged<bool> onShowSaved;
  final VoidCallback onNewList;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MusicList>>(
      stream: owned,
      builder: (context, ownedSnap) => StreamBuilder<List<MusicList>>(
        stream: saved,
        builder: (context, savedSnap) => _content(
          context,
          ownedSnap.data,
          saved == null ? const <MusicList>[] : savedSnap.data,
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<MusicList>? mine, List<MusicList>? savedLists) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final viewingSaved = isMe && showSaved;
    final source = viewingSaved ? savedLists : mine;
    final shown = source == null ? null : applyListQuery(source, query);
    final keyPrefix = viewingSaved ? 'saved' : 'list';

    Widget pill(String key, String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoicePill(key: ValueKey(key), label: label, selected: selected, onTap: onTap),
        );

    final sortLabels = {
      ListSort.recent: l10n.listsSortRecent,
      ListSort.name: l10n.listsSortName,
      ListSort.size: l10n.listsSortSize,
      ListSort.likes: l10n.listsSortLikes,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 22, VSpace.page, 0),
            child: SectionSwitch(
              labels: [
                l10n.listsMineTab(mine?.length ?? 0),
                l10n.listsSavedTab(savedLists?.length ?? 0),
              ],
              keys: const ['lists-mine', 'lists-saved'],
              selected: viewingSaved ? 1 : 0,
              onChanged: (i) => onShowSaved(i == 1),
            ),
          )
        else
          SectionHeader(
            l10n.listsOf(name),
            subtitle: mine == null ? null : l10n.countLists(mine.length),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
          child: TextField(
            key: const ValueKey('lists-search'),
            controller: search,
            textInputAction: TextInputAction.search,
            onChanged: (v) => onQuery(query.copyWith(text: v)),
            style: VText.ui(15, weight: 600),
            decoration: InputDecoration(
              hintText: l10n.listsSearchHint,
              prefixIcon: Icon(Icons.search_rounded, color: c.text3),
              suffixIcon: query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clear,
                      onPressed: () {
                        search.clear();
                        onQuery(query.copyWith(text: ''));
                      },
                      icon: Icon(Icons.close_rounded, color: c.text3),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
            children: [
              pill('lists-kind-all', l10n.filterAll, query.kind == null,
                  () => onQuery(query.copyWith(kind: () => null))),
              pill('lists-kind-list', l10n.listsFilterLists, query.kind == ListKind.list,
                  () => onQuery(query.copyWith(kind: () => query.kind == ListKind.list ? null : ListKind.list))),
              pill('lists-kind-ranking', l10n.listsFilterRankings, query.kind == ListKind.ranking,
                  () => onQuery(query.copyWith(kind: () => query.kind == ListKind.ranking ? null : ListKind.ranking))),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(child: Container(width: 1, height: 18, color: c.line)),
              ),
              pill('lists-type-tracks', l10n.listTypeTracks, query.itemType == ListItemType.tracks,
                  () => onQuery(query.copyWith(itemType: () => query.itemType == ListItemType.tracks ? null : ListItemType.tracks))),
              pill('lists-type-albums', l10n.listTypeAlbums, query.itemType == ListItemType.albums,
                  () => onQuery(query.copyWith(itemType: () => query.itemType == ListItemType.albums ? null : ListItemType.albums))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 10, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  shown == null || source == null
                      ? ''
                      : query.filtering
                          ? l10n.listsShowing(shown.length, source.length)
                          : l10n.countLists(source.length),
                  key: const ValueKey('lists-summary'),
                  style: VText.ui(12, color: c.text3),
                ),
              ),
              if (query.filtering)
                TextButton(
                  key: const ValueKey('lists-clear'),
                  onPressed: () {
                    search.clear();
                    onQuery(query.cleared());
                  },
                  child: Text(l10n.listsClearFilters, style: VText.ui(13, weight: 700, color: c.accent)),
                ),
              PopupMenuButton<ListSort>(
                key: const ValueKey('lists-sort'),
                tooltip: l10n.sortBy,
                initialValue: query.sort,
                onSelected: (s) => onQuery(query.copyWith(sort: s)),
                itemBuilder: (_) => [
                  for (final s in ListSort.values)
                    PopupMenuItem(
                      key: ValueKey('lists-sort-${s.name}'),
                      value: s,
                      child: Text(sortLabels[s]!),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert_rounded, size: 18, color: c.text2),
                      const SizedBox(width: 4),
                      Text(sortLabels[query.sort]!, style: VText.ui(13, weight: 700, color: c.text2)),
                    ],
                  ),
                ),
              ),
              if (isMe && !viewingSaved)
                TextButton(
                  key: const ValueKey('new-list'),
                  onPressed: onNewList,
                  child: Text(l10n.listNew, style: VText.ui(13, weight: 700, color: c.accent)),
                ),
            ],
          ),
        ),
        if (shown == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: VSpace.page),
            child: Skeleton(height: 70, radius: 18),
          )
        else if (source!.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 4),
            child: Text(
              viewingSaved
                  ? l10n.listsSavedEmpty
                  : isMe
                      ? l10n.listsEmptyMine
                      : l10n.listsEmptyTheirs,
              key: ValueKey('$keyPrefix-empty'),
              style: VText.ui(13, color: c.text3, height: 1.4),
            ),
          )
        else if (shown.isEmpty)
          EmptyState(
            key: const ValueKey('lists-no-match'),
            title: l10n.listsNoMatchTitle,
            message: l10n.listsNoMatchBody,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 0),
            child: Column(
              children: [
                for (final (i, list) in shown.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListRowTile(
                      key: ValueKey('$keyPrefix-$i'),
                      list: list,
                      onTap: () => openList(context, listId: list.id, initial: list),
                      trailing: Icon(Icons.chevron_right_rounded, color: c.text3),
                    ),
                  ).animate().fadeIn(delay: (30 * (i % 10)).ms, duration: 280.ms),
              ],
            ),
          ),
      ],
    );
  }
}

/// "N seguidores · N seguidos"; cada parte abre su lista.
class _FollowCounts extends StatelessWidget {
  const _FollowCounts({required this.profile, required this.isMe});

  final UserProfile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    Widget part(String key, int n, String word, bool followers) {
      return GestureDetector(
        key: ValueKey(key),
        behavior: HitTestBehavior.opaque,
        onTap: () => openFollowList(
          context,
          uid: profile.uid,
          name: profile.name,
          followers: followers,
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$n ', style: VText.ui(14, weight: 800)),
              TextSpan(
                text: word,
                style: VText.ui(14, color: c.text2),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        part('followers', profile.followersCount, context.l10n.followersWord(profile.followersCount), true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: VText.ui(14, color: c.text3)),
        ),
        part('following', profile.followingCount, context.l10n.followingWord(profile.followingCount), false),
      ],
    );
  }
}

/// Botón redondo y compacto del encabezado del perfil (compartir, configuración).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface2.withValues(alpha: 0.8),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: c.text),
          ),
        ),
      ),
    );
  }
}

class _MiniHeader extends StatelessWidget {
  const _MiniHeader({
    required this.label,
    required this.pickKey,
    required this.onPick,
  });

  final String label;
  final String pickKey;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      children: [
        Text(label, style: VText.label(11, color: c.text3)),
        const Spacer(),
        if (onPick != null)
          GestureDetector(
            key: ValueKey(pickKey),
            onTap: onPick,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                context.l10n.pick,
                style: VText.ui(13, weight: 700, color: c.accent),
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: VText.display(32, height: 1, color: color ?? c.text),
          ),
          const SizedBox(height: 4),
          Text(label, style: VText.label(10, color: c.text3)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(width: 1, height: 34, color: c.line);
  }
}

class _AffinityCard extends StatelessWidget {
  const _AffinityCard({
    required this.theirs,
    required this.mine,
    required this.name,
  });

  final List<RatingEntry> theirs;
  final Future<List<RatingEntry>> mine;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return FutureBuilder<List<RatingEntry>>(
      future: mine,
      builder: (context, snap) {
        final mineList = snap.data;
        if (mineList == null) return const SizedBox.shrink();
        final theirScores = {for (final r in theirs) r.albumId: r};
        final common = <(RatingEntry, RatingEntry)>[];
        for (final m in mineList) {
          final t = theirScores[m.albumId];
          if (t != null) common.add((m, t));
        }
        int? affinity;
        if (common.isNotEmpty) {
          final diff = common.fold<int>(
                  0, (s, pair) => s + (pair.$1.score - pair.$2.score).abs()) /
              common.length;
          affinity = (100 - diff * 10).round().clamp(0, 100);
        }
        final color = affinity == null ? c.text3 : c.score(affinity / 10);
        return Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.affinity, style: VText.label(11, color: c.text3)),
                      const SizedBox(height: 4),
                      Text(
                        affinity == null ? '–' : '$affinity%',
                        style: VText.display(44, color: color, height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        common.isEmpty
                            ? context.l10n.affinityNone
                            : context.l10n.affinityBasis(common.length),
                        style: VText.ui(13, color: c.text2),
                      ),
                    ],
                  ),
                ),
                if (common.isNotEmpty)
                  SizedBox(
                    width: 48.0 + 26.0 * (common.take(4).length - 1),
                    height: 48,
                    child: Stack(
                      children: [
                        for (final (i, pair) in common.take(4).indexed)
                          Positioned(
                            left: 26.0 * i,
                            child: AlbumCover(
                              url: pair.$2.album.smallCover,
                              size: 48,
                              radius: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }
}

class _FavoritesRow extends StatelessWidget {
  const _FavoritesRow({
    required this.favorites,
    required this.uid,
    required this.onEmptyTap,
  });

  final List<Album> favorites;
  final String uid;
  final VoidCallback? onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < UserRepo.maxFavorites; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: i < favorites.length
                ? GestureDetector(
                    onTap: () => openAlbum(
                      context,
                      favorites[i],
                      heroTag: 'fav-$uid-${favorites[i].id}',
                    ),
                    child: AlbumCover(
                      url: favorites[i].smallCover,
                      radius: 16,
                      heroTag: 'fav-$uid-${favorites[i].id}',
                    ),
                  )
                    .animate()
                    .fadeIn(delay: (60 * i).ms)
                    .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack)
                : GestureDetector(
                    onTap: onEmptyTap,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.line, width: 1.5),
                          color: c.surface.withValues(alpha: 0.4),
                        ),
                        child: onEmptyTap == null
                            ? null
                            : Icon(
                                Icons.add_rounded,
                                color: c.text3,
                              ),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _ArtistsRow extends StatelessWidget {
  const _ArtistsRow({required this.artists, required this.onEmptyTap});

  final List<Artist> artists;
  final VoidCallback? onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < UserRepo.maxFavorites; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: i < artists.length
                ? GestureDetector(
                    key: ValueKey('fav-artist-$i'),
                    onTap: () => openArtist(context, artists[i]),
                    child: Column(
                      children: [
                        ArtistAvatar(artist: artists[i]),
                        const SizedBox(height: 8),
                        Text(
                          artists[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: VText.ui(13, weight: 700),
                        ),
                      ],
                    ),
                  )
                    .animate()
                    .fadeIn(delay: (60 * i).ms)
                    .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack)
                : GestureDetector(
                    onTap: onEmptyTap,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.line, width: 1.5),
                              color: c.surface.withValues(alpha: 0.4),
                            ),
                            child: onEmptyTap == null
                                ? null
                                : Icon(
                                    Icons.add_rounded,
                                    color: c.text3,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          onEmptyTap == null ? '' : context.l10n.artistLabel,
                          style: VText.ui(13, color: c.text3),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: c.text3.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
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
  late final List<Album> _selected = [...widget.initial];

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
    final albums = <String, Album>{};
    for (final r in widget.ratings) {
      albums.putIfAbsent(r.albumId, () => r.album);
    }
    final list = albums.values.where((a) => albumMatches(a, _query)).toList();
    // Con el teclado abierto (buscando) la hoja sube y se encoge para que el
    // botón de guardar siga a la vista.
    final screen = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final height = math.min(screen * 0.78, screen - keyboard - 40);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.favoritesPickerTitle, style: VText.display(30, height: 1)),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.favoritesPickerHint,
                          style: VText.ui(13, color: c.text2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_selected.length}/$_max',
                    style: VText.display(24, color: c.accent),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: TextField(
                key: const ValueKey('favorites-search'),
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                style: VText.ui(16, weight: 600),
                decoration: InputDecoration(
                  hintText: context.l10n.favoritesSearchHint,
                  prefixIcon: Icon(Icons.search_rounded, color: c.text3),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.clear,
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: Icon(Icons.close_rounded, color: c.text3),
                        ),
                ),
              ),
            ),
            if (list.isEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                  child: Text(
                    context.l10n.favoritesNoMatch(_query.trim()),
                    key: const ValueKey('favorites-no-match'),
                    textAlign: TextAlign.center,
                    style: VText.ui(14, color: c.text3, height: 1.4),
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
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
                            child: AlbumCover(url: album.smallCover, radius: 12),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? c.accent : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _OrderBadge(index + 1),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: FilledButton(
                key: const ValueKey('favorites-save'),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(context.l10n.favoritesSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: VText.ui(13, weight: 800, color: c.onAccent),
      ),
    );
  }
}

/// Buscar artistas en Spotify y elegir hasta tres.
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
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final results = _results;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.artistsPickerTitle, style: VText.display(30, height: 1)),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.artistsPickerHint,
                          style: VText.ui(13, color: c.text2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_selected.length}/$_max',
                    style: VText.display(24, color: c.accent),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextField(
                key: const ValueKey('artist-search'),
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                style: VText.ui(16, weight: 600),
                decoration: InputDecoration(
                  hintText: context.l10n.artistsSearchHint,
                  prefixIcon: Icon(Icons.search_rounded, color: c.text3),
                ),
              ),
            ),
            if (_selected.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  itemCount: _selected.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = _selected[i];
                    return Pill(
                      key: ValueKey('artist-selected-$i'),
                      onTap: () => _toggle(a),
                      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                      color: c.accent.withValues(alpha: 0.14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ArtistAvatar(artist: a, size: 26),
                          const SizedBox(width: 8),
                          Text(a.name, style: VText.ui(13, weight: 700, color: c.accent)),
                          const SizedBox(width: 6),
                          Icon(Icons.close_rounded, size: 14, color: c.accent),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: _error != null
                  ? EmptyState(
                      title: context.l10n.spotifyNoResponse,
                      message: describeError(_error, context.l10n),
                      labelColor: c.danger,
                      action: TextButton(
                        onPressed: () => _search(_controller.text.trim()),
                        child: Text(context.l10n.retry),
                      ),
                    )
                  : _loading && results == null
                      ? ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                          itemCount: 5,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, _) => const Skeleton(height: 56, radius: 16),
                        )
                      : results == null
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                              child: Text(
                                context.l10n.artistsPrompt,
                                textAlign: TextAlign.center,
                                style: VText.ui(14, color: c.text3),
                              ),
                            )
                          : results.isEmpty
                              ? EmptyState(
                                  title: context.l10n.searchNothingTitle,
                                  message: context.l10n.addNothingBody,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                                  physics: const BouncingScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                                ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: FilledButton(
                key: const ValueKey('artists-save'),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(context.l10n.artistsSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? c.accent.withValues(alpha: 0.12) : c.surface2,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: dimmed ? 0.45 : 1,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ArtistAvatar(artist: artist, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(15, weight: 700),
                        ),
                        if (artist.genres.isNotEmpty)
                          Text(
                            artist.genres.take(3).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VText.ui(12, color: c.text2),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (selected)
                    _OrderBadge(order!)
                  else
                    Icon(Icons.add_circle_outline_rounded, color: c.text3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
