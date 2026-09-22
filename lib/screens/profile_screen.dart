import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/album.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../widgets/album_cover.dart';
import '../widgets/histogram.dart';
import '../widgets/misc.dart';
import '../widgets/score_widgets.dart';
import '../widgets/user_avatar.dart';
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
  Future<List<RatingEntry>>? _mineForAffinity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ratings != null) return;
    final services = ServicesScope.of(context);
    _ratings = services.ratings.userRatings(widget.uid);
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
          initialName: profile.name,
          initialColor: profile.colorValue,
          initialAvatarUrl: profile.avatarUrl,
          onSubmit: (name, color, avatar, remove) async {
            String? url = remove ? null : profile.avatarUrl;
            if (avatar != null) {
              url = await services.users.uploadAvatar(profile.uid, avatar);
            }
            await services.users.updateProfile(
              RaterInfo(
                uid: profile.uid,
                name: name,
                colorValue: color,
                avatarUrl: url,
              ),
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
        initial: profile.favorites,
      ),
    );
    if (picked == null) return;
    await services.users.setFavorites(profile.uid, picked);
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
            isMe: widget.isMe,
            standalone: widget.standalone,
            mineForAffinity: _mineForAffinity,
            onEdit: () => _edit(profile),
            onPickFavorites: ratings == null
                ? null
                : () => _pickFavorites(profile, ratings),
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
    required this.isMe,
    required this.standalone,
    required this.mineForAffinity,
    required this.onEdit,
    required this.onPickFavorites,
  });

  final UserProfile profile;
  final List<RatingEntry>? ratings;
  final bool isMe;
  final bool standalone;
  final Future<List<RatingEntry>>? mineForAffinity;
  final VoidCallback onEdit;
  final VoidCallback? onPickFavorites;

  @override
  Widget build(BuildContext context) {
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

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AmbientGlow(
            color: profile.color.withValues(alpha: 0.55),
            height: 380,
          ),
        ),
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  VSpace.page,
                  topPad + (standalone ? 62 : 22),
                  VSpace.page,
                  0,
                ),
                child: Row(
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
                          Text(
                            'En Vinilo desde ${monthYear(profile.createdAt).toLowerCase()}',
                            style: VText.ui(13, color: VColors.text2),
                          ),
                        ],
                      ),
                    ),
                    if (isMe)
                      IconButton(
                        onPressed: onEdit,
                        tooltip: 'Editar perfil',
                        icon: const Icon(Icons.tune_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: VColors.surface2.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: VColors.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: VColors.line),
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
                        color: average == null ? null : Score.color(average),
                      ),
                      const _StatDivider(),
                      _Stat(value: '$thisMonth', label: 'ESTE MES'),
                    ],
                  ),
                ),
              ),
            ),
            if (!isMe && mineForAffinity != null)
              SliverToBoxAdapter(
                child: _AffinityCard(
                  theirs: list,
                  mine: mineForAffinity!,
                  name: profile.name,
                ),
              ),
            SliverToBoxAdapter(
              child: SectionHeader(
                'Favoritos',
                subtitle: isMe
                    ? 'Los cuatro discos que te definen'
                    : 'Los cuatro discos que le definen',
                action: isMe && list.isNotEmpty
                    ? Pill(
                        key: const ValueKey('pick-favorites'),
                        onTap: onPickFavorites,
                        child: Text('Elegir', style: VText.ui(13, weight: 700)),
                      )
                    : null,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                child: _FavoritesRow(
                  favorites: profile.favorites,
                  uid: profile.uid,
                  onEmptyTap: isMe && list.isNotEmpty ? onPickFavorites : null,
                ),
              ),
            ),
            if (list.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  'Distribución',
                  subtitle: isMe
                      ? 'Cómo repartes tus notas'
                      : 'Cómo reparte sus notas',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    decoration: BoxDecoration(
                      color: VColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ScoreHistogram(hist: hist, height: 64),
                  ),
                ),
              ),
            ],
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
              _Diary(entries: list),
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
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: VText.display(32, height: 1, color: color ?? VColors.text),
          ),
          const SizedBox(height: 4),
          Text(label, style: VText.label(10)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: VColors.line);
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
        final color = affinity == null ? VColors.text3 : Score.color(affinity / 10);
        return Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: BoxDecoration(
              color: VColors.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AFINIDAD MUSICAL', style: VText.label(11)),
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
                        style: VText.ui(13, color: VColors.text2),
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
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 10),
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
                      radius: 14,
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
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: VColors.line, width: 1.5),
                          color: VColors.surface.withValues(alpha: 0.4),
                        ),
                        child: onEmptyTap == null
                            ? null
                            : const Icon(
                                Icons.add_rounded,
                                color: VColors.text3,
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

class _Diary extends StatelessWidget {
  const _Diary({required this.entries});

  final List<RatingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final items = <Object>[];
    String? currentMonth;
    for (final e in entries) {
      final key = monthYear(e.createdAt);
      if (key != currentMonth) {
        currentMonth = key;
        items.add(key);
      }
      items.add(e);
    }
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is String) {
          return Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, i == 0 ? 4 : 22, VSpace.page, 8),
            child: Text(item.toUpperCase(), style: VText.label(11)),
          );
        }
        final e = item as RatingEntry;
        return _DiaryRow(entry: e)
            .animate()
            .fadeIn(delay: (30 * (i % 10)).ms, duration: 350.ms);
      },
    );
  }
}

class _DiaryRow extends StatelessWidget {
  const _DiaryRow({required this.entry});

  final RatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'diary-${entry.id}';
    return InkWell(
      key: ValueKey('diary-${entry.albumId}'),
      onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Text(
                    '${entry.createdAt.day}',
                    style: VText.display(24, height: 1),
                  ),
                  Text(
                    monthShort(entry.createdAt.month).toUpperCase(),
                    style: VText.label(9),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AlbumCover(
              url: entry.album.smallCover,
              size: 56,
              radius: 10,
              heroTag: heroTag,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(15, weight: 700),
                  ),
                  Text(
                    entry.album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12, color: VColors.text2),
                  ),
                  if (entry.hasNote)
                    Text(
                      entry.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.display(14, italic: true, color: VColors.text3, height: 1.3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ScoreNumeral(score: entry.score, size: 32),
          ],
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: VColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: VColors.line)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VColors.text3.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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

class _FavoritesPicker extends StatefulWidget {
  const _FavoritesPicker({required this.ratings, required this.initial});

  final List<RatingEntry> ratings;
  final List<Album> initial;

  @override
  State<_FavoritesPicker> createState() => _FavoritesPickerState();
}

class _FavoritesPickerState extends State<_FavoritesPicker> {
  late final List<Album> _selected = [...widget.initial];

  void _toggle(Album album) {
    final index = _selected.indexWhere((a) => a.id == album.id);
    setState(() {
      if (index >= 0) {
        _selected.removeAt(index);
      } else if (_selected.length < 4) {
        HapticFeedback.selectionClick();
        _selected.add(album);
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final albums = <String, Album>{};
    for (final r in widget.ratings) {
      albums.putIfAbsent(r.albumId, () => r.album);
    }
    final list = albums.values.toList();
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: VColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: VColors.line)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: VColors.text3.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tus favoritos', style: VText.display(30, height: 1)),
                      const SizedBox(height: 4),
                      Text(
                        'Elige hasta cuatro, en el orden que quieras.',
                        style: VText.ui(13, color: VColors.text2),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_selected.length}/4',
                  style: VText.display(24, color: VColors.accent),
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
                        opacity: selected || _selected.length < 4 ? 1 : 0.4,
                        child: AlbumCover(url: album.smallCover, radius: 12),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? VColors.accent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: VColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: VText.ui(13, weight: 800, color: VColors.onAccent),
                            ),
                          ),
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
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Guardar favoritos'),
            ),
          ),
        ],
      ),
    );
  }
}
