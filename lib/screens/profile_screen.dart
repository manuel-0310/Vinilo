import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../services/user_repo.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'favorites_pickers.dart';
import 'list_form_sheet.dart';
import 'profile_header.dart';
import 'profile_lists_tab.dart';
import 'profile_tab.dart';
import 'routes.dart';

/// El perfil, propio (la pestaña Perfil) o de otra persona (ruta propia):
/// el encabezado (`ProfileHeader`), las pestañas "Perfil" y "Listas", y su
/// contenido (`ProfileTab`, `ProfileListsTab`). Al bajar, el nombre con
/// "N discos · promedio" y las pestañas quedan fijos arriba
/// (`ProfileCompactBar`), en las dos pestañas.
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

/// Las dos pestañas: favoritos, "Cómo califico" y diario, o listas.
enum _ProfileSection { perfil, listas }

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileSection _section = _ProfileSection.perfil;

  // Pestaña "Listas": se conservan al ir y volver de "Perfil".
  ListQuery _listQuery = const ListQuery();
  bool _showSavedLists = false;
  final _listSearch = TextEditingController();

  Stream<UserProfile?>? _profile;
  Stream<List<RatingEntry>>? _ratings;
  Stream<List<MusicList>>? _lists;
  Stream<List<MusicList>>? _saved;
  Future<List<RatingEntry>>? _mineForAffinity;
  Stream<bool>? _followsMe;

  final ScrollController _scroll = ScrollController();

  /// Las pestañas dentro del contenido: cuando llegan a donde van las de la
  /// barra compacta, esta aparece.
  final GlobalKey _tabsKey = GlobalKey();
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

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
        _followsMe = services.follows.isFollowing(widget.uid, me.uid);
      }
    }
  }

  @override
  void dispose() {
    _listSearch.dispose();
    _scroll.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  void _onScroll() {
    final box = _tabsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !mounted) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final pinnedAt = MediaQuery.paddingOf(context).top + ProfileCompactBar.tabsOffset;
    _collapsed.value = top <= pinnedAt;
  }

  void _setSection(_ProfileSection section) {
    setState(() => _section = section);
    // El contenido cambia de alto: la barra compacta se revisa al dibujar.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  Future<void> _pickFavorites(UserProfile profile, List<RatingEntry> ratings) async {
    final services = ServicesScope.of(context);
    final picked = await showFavoritesPicker(
      context,
      ratings: ratings,
      initial: profile.favorites.take(UserRepo.maxFavorites).toList(),
    );
    if (picked == null) return;
    await services.users.setFavorites(profile.uid, picked);
  }

  Future<void> _pickArtists(UserProfile profile) async {
    final services = ServicesScope.of(context);
    final picked = await showArtistsPicker(context, initial: profile.favoriteArtists);
    if (picked == null) return;
    await services.users.setFavoriteArtists(profile.uid, picked);
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

  Widget _tabs() {
    final l = context.l10n;
    return VTabs(
      labels: [l.tabProfile, l.profileListsTab],
      keys: const ['profile-section-perfil', 'profile-section-listas'],
      selected: _section.index,
      onChanged: (i) => _setSection(_ProfileSection.values[i]),
    );
  }

  Widget _body(UserProfile profile) {
    return StreamBuilder<List<RatingEntry>>(
      stream: _ratings,
      builder: (context, snap) {
        final ratings = snap.data;
        return Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              // Sin rebote arriba: por encima del banner no hay nada.
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    profile: profile,
                    isMe: widget.isMe,
                    standalone: widget.standalone,
                    ratings: ratings,
                    mine: _mineForAffinity,
                    followsMe: _followsMe,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: widget.isMe ? 14 : 0),
                    child: KeyedSubtree(key: _tabsKey, child: _tabs()),
                  ),
                ),
                if (_section == _ProfileSection.perfil)
                  ProfileTab(
                    profile: profile,
                    isMe: widget.isMe,
                    ratings: ratings,
                    onPickFavorites: ratings == null ? null : () => _pickFavorites(profile, ratings),
                    onPickArtists: () => _pickArtists(profile),
                  )
                else
                  SliverToBoxAdapter(
                    child: ProfileListsTab(
                      owned: _lists,
                      saved: widget.isMe ? _saved : null,
                      isMe: widget.isMe,
                      search: _listSearch,
                      query: _listQuery,
                      onQuery: (q) => setState(() => _listQuery = q),
                      showSaved: _showSavedLists,
                      onShowSaved: (v) => setState(() => _showSavedLists = v),
                      onNewList: () => _newList(profile),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: widget.standalone
                        ? MediaQuery.paddingOf(context).bottom + 30
                        : VSpace.tabBarClearance,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _collapsed,
                builder: (context, collapsed, _) => collapsed
                    ? ProfileCompactBar(profile: profile, ratings: ratings, tabs: _tabs())
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (widget.isMe) {
      final me = CurrentUser.maybeOf(context);
      return Scaffold(body: me == null ? const SizedBox.shrink() : _body(me));
    }
    return Scaffold(
      body: StreamBuilder<UserProfile?>(
        stream: _profile,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          final profile = snap.data;
          if (profile == null) {
            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: VIconButton(
                        key: const ValueKey('back'),
                        icon: VIcon.back,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  VEmptyState(
                    title: l.profileNotFound,
                    message: l.profileNotFoundBody,
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 28, VSpace.page, 24),
                  ),
                ],
              ),
            );
          }
          return _body(profile);
        },
      ),
    );
  }
}

/// Mientras llega el perfil de otra persona: el banner plano y volver.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: topPad + profileBannerBelowStatus,
          color: c.surface,
          alignment: Alignment.topLeft,
          padding: EdgeInsets.fromLTRB(16, topPad + 4, 16, 0),
          child: VIconButton(
            key: const ValueKey('back'),
            icon: VIcon.back,
            style: VIconButtonStyle.filled,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(VSpace.page, 64, VSpace.page, 0),
          child: VSkeleton(width: 220, height: 40),
        ),
      ],
    );
  }
}
