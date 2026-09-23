import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../services/user_repo.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/diary_row.dart';
import '../widgets/follow_button.dart';
import '../widgets/histogram.dart';
import '../widgets/list_strip.dart';
import '../widgets/misc.dart';
import '../widgets/user_avatar.dart';
import 'list_form_sheet.dart';
import 'profile_form.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _edit(UserProfile profile) async {
    final services = ServicesScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(
        title: 'Tu perfil',
        child: ProfileForm(
          submitLabel: 'Guardar',
          showBanner: true,
          showUsername: true,
          initialName: profile.name,
          initialColor: profile.colorValue,
          initialUsername: profile.username,
          forUid: profile.uid,
          initialAvatarUrl: profile.avatarUrl,
          initialBannerUrl: profile.bannerUrl,
          onSubmit: (edit) async {
            // Primero el @usuario: si ya lo tomó alguien, falla aquí y no se
            // guarda nada más.
            if (edit.username != null && edit.username != profile.username) {
              await services.users.setUsername(
                profile.uid,
                edit.username!,
                previous: profile.username,
              );
            }
            String? avatarUrl = edit.removeAvatar ? null : profile.avatarUrl;
            if (edit.avatar != null) {
              avatarUrl = await services.users.uploadAvatar(profile.uid, edit.avatar!);
            }
            String? bannerUrl = edit.removeBanner ? null : profile.bannerUrl;
            if (edit.banner != null) {
              bannerUrl = await services.users.uploadBanner(profile.uid, edit.banner!);
            }
            await services.users.updateProfile(
              RaterInfo(
                uid: profile.uid,
                name: edit.name,
                colorValue: edit.colorValue,
                avatarUrl: avatarUrl,
              ),
              bannerUrl: bannerUrl,
              updateBanner: edit.banner != null || edit.removeBanner,
              username: edit.username ?? profile.username,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      ),
    );
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
        SnackBar(content: Text('No se pudo crear la lista: $e')),
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
            mineForAffinity: _mineForAffinity,
            onEdit: () => _edit(profile),
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
                const Center(
                  child: EmptyState(
                    title: 'Perfil no encontrado',
                    message: 'Esta persona ya no está en Vinilo.',
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
    required this.mineForAffinity,
    required this.onEdit,
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
  final Future<List<RatingEntry>>? mineForAffinity;
  final VoidCallback onEdit;
  final VoidCallback onNewList;
  final VoidCallback? onPickFavorites;
  final VoidCallback onPickArtists;

  static const int _diaryPreview = 5;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final list = ratings ?? const <RatingEntry>[];
    final now = DateTime.now();
    final thisMonth = list
        .where((r) => r.createdAt.year == now.year && r.createdAt.month == now.month)
        .length;
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
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      'En Vinilo desde ${monthYear(profile.createdAt).toLowerCase()}',
                                      style: VText.ui(
                                        profile.username == null ? 13 : 12,
                                        color: profile.username == null ? c.text2 : c.text3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe)
                              Padding(
                                padding: EdgeInsets.only(top: banner != null ? 42 : 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _HeaderButton(
                                      key: const ValueKey('edit-profile'),
                                      icon: Icons.tune_rounded,
                                      tooltip: 'Editar perfil',
                                      onTap: onEdit,
                                    ),
                                    const SizedBox(width: 8),
                                    _HeaderButton(
                                      key: const ValueKey('settings'),
                                      icon: Icons.settings_rounded,
                                      tooltip: 'Configuración',
                                      onTap: () => openSettings(context),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.only(top: banner != null ? 42 : 0),
                                child: FollowButton(
                                  person: profile.person,
                                  testKey: 'follow-profile',
                                ),
                              ),
                          ],
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
                                label: list.length == 1 ? 'DISCO' : 'DISCOS',
                              ),
                              const _StatDivider(),
                              _Stat(
                                value: average == null ? '–' : Score.formatAverage(average),
                                label: 'PROMEDIO',
                                color: average == null ? null : c.score(average),
                              ),
                              const _StatDivider(),
                              _Stat(value: '$thisMonth', label: 'ESTE MES'),
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
            SliverToBoxAdapter(
              child: SectionHeader(
                'Favoritos',
                subtitle: isMe
                    ? 'Tres discos y tres artistas que te definen'
                    : 'Tres discos y tres artistas que le definen',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniHeader(
                      label: 'DISCOS',
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
                      label: 'ARTISTAS',
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
            SliverToBoxAdapter(
              child: _ListsSection(
                title: 'Listas',
                stream: lists,
                keyPrefix: 'list',
                subtitle: isMe
                    ? 'Tus listas y rankings de canciones o discos'
                    : 'Listas y rankings de ${profile.name}',
                action: isMe
                    ? GestureDetector(
                        key: const ValueKey('new-list'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onNewList,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                          child: Text(
                            'Nueva lista',
                            style: VText.ui(13, weight: 700, color: c.accent),
                          ),
                        ),
                      )
                    : null,
                emptyText: isMe
                    ? 'Todavía no tienes listas. Crea una con "Nueva lista" o desde la pantalla de un disco.'
                    : 'Todavía no tiene listas.',
              ),
            ),
            if (isMe && saved != null)
              SliverToBoxAdapter(
                child: _ListsSection(
                  title: 'Guardadas',
                  stream: saved,
                  keyPrefix: 'saved',
                  subtitle: 'Listas de otras personas que guardaste. Solo tú las ves aquí.',
                  emptyText: 'Guarda listas de otras personas y aparecerán aquí.',
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
                'Diario',
                subtitle: ratings == null
                    ? 'Cargando…'
                    : plural(list.length, 'disco calificado', 'discos calificados'),
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
                  title: isMe ? 'Tu diario está vacío' : 'Aún no hay notas',
                  message: isMe
                      ? 'Busca un disco y ponle nota. Aquí quedará tu historial, mes a mes.'
                      : 'Cuando ${profile.name} califique algo, aparecerá aquí.',
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
                        'Ver más (${list.length - _diaryPreview})',
                        style: VText.ui(13, weight: 700),
                      ),
                    ),
                  ),
                ),
              ),
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

/// Encabezado + fila de listas (propias o guardadas) con sus estados de
/// carga y vacío.
class _ListsSection extends StatelessWidget {
  const _ListsSection({
    required this.title,
    required this.stream,
    required this.keyPrefix,
    required this.subtitle,
    required this.emptyText,
    this.action,
  });

  final String title;
  final Stream<List<MusicList>>? stream;
  final String keyPrefix;
  final String subtitle;
  final String emptyText;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return StreamBuilder<List<MusicList>>(
      stream: stream,
      builder: (context, snap) {
        final lists = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title,
              subtitle: lists == null
                  ? subtitle
                  : lists.isEmpty
                      ? subtitle
                      : '${lists.length} ${lists.length == 1 ? 'lista' : 'listas'}',
              action: action,
            ),
            if (lists == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: VSpace.page),
                child: Skeleton(height: 132, radius: 16),
              )
            else if (lists.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 4),
                child: Text(
                  emptyText,
                  key: ValueKey('$keyPrefix-empty'),
                  style: VText.ui(13, color: c.text3, height: 1.4),
                ),
              )
            else
              ListStrip(lists: lists, keyPrefix: keyPrefix),
          ],
        );
      },
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
    Widget part(String key, int n, String one, String many, bool followers) {
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
                text: n == 1 ? one : many,
                style: VText.ui(14, color: c.text2),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        part('followers', profile.followersCount, 'seguidor', 'seguidores', true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: VText.ui(14, color: c.text3)),
        ),
        part('following', profile.followingCount, 'seguido', 'seguidos', false),
      ],
    );
  }
}

/// Botón redondo y compacto del encabezado del perfil (editar, configuración).
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
                'Elegir',
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
                      Text('AFINIDAD MUSICAL', style: VText.label(11, color: c.text3)),
                      const SizedBox(height: 4),
                      Text(
                        affinity == null ? '–' : '$affinity%',
                        style: VText.display(44, color: color, height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        common.isEmpty
                            ? 'Todavía no tienen discos en común'
                            : 'Según ${plural(common.length, 'disco en común', 'discos en común')}',
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
                          onEmptyTap == null ? '' : 'Artista',
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

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              Text(title, style: VText.display(30)),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
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
    final list = albums.values.toList();
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return Container(
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
                      Text('Tus discos', style: VText.display(30, height: 1)),
                      const SizedBox(height: 4),
                      Text(
                        'Elige hasta tres, en el orden que quieras.',
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
          Expanded(
            child: GridView.builder(
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
              child: const Text('Guardar discos'),
            ),
          ),
        ],
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
                        Text('Tus artistas', style: VText.display(30, height: 1)),
                        const SizedBox(height: 4),
                        Text(
                          'Busca en Spotify y elige hasta tres.',
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
                  hintText: 'Nombre del artista',
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
                      title: 'Spotify no respondió',
                      message: '$_error',
                      labelColor: c.danger,
                      action: TextButton(
                        onPressed: () => _search(_controller.text.trim()),
                        child: const Text('Reintentar'),
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
                                'Escribe el nombre de un artista para buscarlo.',
                                textAlign: TextAlign.center,
                                style: VText.ui(14, color: c.text3),
                              ),
                            )
                          : results.isEmpty
                              ? const EmptyState(
                                  title: 'Nada por aquí',
                                  message: 'Prueba con otro nombre.',
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
                child: const Text('Guardar artistas'),
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
