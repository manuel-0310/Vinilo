import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/user_repo.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/diary_row.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_ruler.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// Cuántas notas enseña el diario del perfil (el resto, en "Ver todo").
const int profileDiaryPreview = 5;

/// La pestaña "Perfil": favoritos (en el propio, "Favoritos" con discos y
/// artistas y "Elegir"; en el ajeno, sus tres discos en rejilla sin títulos
/// y después sus artistas), "Cómo califico" con el histograma y el diario
/// de los últimos meses con "Ver todo".
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.profile,
    required this.isMe,
    required this.ratings,
    required this.onPickFavorites,
    required this.onPickArtists,
  });

  final UserProfile profile;
  final bool isMe;
  final List<RatingEntry>? ratings;
  final VoidCallback? onPickFavorites;
  final VoidCallback onPickArtists;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final list = ratings;
    final favorites = profile.favorites.take(UserRepo.maxFavorites).toList();
    final artists = profile.favoriteArtists.take(UserRepo.maxFavorites).toList();
    final canPickAlbums = isMe && (list?.isNotEmpty ?? false);
    // El diario va por fecha de la nota, lo más nuevo arriba.
    final diary = [...?list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: isMe
              ? _MyFavorites(
                  favorites: favorites,
                  artists: artists,
                  uid: profile.uid,
                  onPickAlbums: canPickAlbums ? onPickFavorites : null,
                  onPickArtists: onPickArtists,
                )
              : _TheirFavorites(favorites: favorites, artists: artists, uid: profile.uid),
        ),
        if (list != null && list.isNotEmpty)
          SliverToBoxAdapter(child: _HowIRate(ratings: list, isMe: isMe)),
        SliverToBoxAdapter(
          child: VBlockTitle(
            l.diary,
            subtitle: list == null ? l.loading : l.countRatedAlbums(list.length),
            action: list != null && list.isNotEmpty ? l.seeAll : null,
            actionKey: const ValueKey('diary-more'),
            onAction: () => openDiary(
              context,
              uid: profile.uid,
              name: profile.name,
              isMe: isMe,
              initial: diary,
            ),
            padding: const EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, 0),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        if (list == null)
          SliverList.builder(
            itemCount: 3,
            itemBuilder: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 48),
                  VSkeleton(width: 48, height: 48),
                  SizedBox(width: 12),
                  Expanded(child: VSkeleton(height: 30)),
                ],
              ),
            ),
          )
        else if (list.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: VEmptyState(
                title: isMe ? l.diaryEmptyMine : l.diaryEmptyTheirs,
                message: isMe ? l.diaryEmptyMineBody : l.diaryEmptyTheirsBody(profile.name),
              ),
            ),
          )
        else
          DiaryList(
            entries: diary.take(profileDiaryPreview).toList(),
            monthCounts: DiaryList.countByMonth(diary),
          ),
      ],
    );
  }
}

/// "DISCOS" o "ARTISTAS" y, en el perfil propio, "Elegir" en énfasis.
class _FavLabel extends StatelessWidget {
  const _FavLabel({required this.label, this.onPick, this.pickKey});

  final String label;
  final VoidCallback? onPick;
  final String? pickKey;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      children: [
        Expanded(child: VMono(label)),
        if (onPick != null)
          Pressable(
            key: pickKey == null ? null : ValueKey(pickKey),
            onTap: onPick,
            builder: (context, pressed) => Opacity(
              opacity: pressed ? 0.6 : 1,
              child: VMono(context.l10n.pick, color: c.accent),
            ),
          ),
      ],
    );
  }
}

/// "Favoritos" del perfil propio: tres discos con su título y tres artistas
/// en círculo con su nombre. Los huecos vacíos llevan un + para elegir.
class _MyFavorites extends StatelessWidget {
  const _MyFavorites({
    required this.favorites,
    required this.artists,
    required this.uid,
    required this.onPickAlbums,
    required this.onPickArtists,
  });

  final List<Album> favorites;
  final List<Artist> artists;
  final String uid;
  final VoidCallback? onPickAlbums;
  final VoidCallback onPickArtists;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.favorites, style: VText.display(30, weight: 700, stretch: 70, height: 1, tracking: 0)),
          const SizedBox(height: 4),
          Text(l.favoritesMine, style: VText.ui(13.5, color: VColors.of(context).ink3)),
          const SizedBox(height: 16),
          _FavLabel(label: l.favoritesAlbumsLabel, onPick: onPickAlbums, pickKey: 'pick-favorites'),
          const SizedBox(height: 8),
          _Row3(
            gap: 8,
            children: [
              for (var i = 0; i < UserRepo.maxFavorites; i++)
                i < favorites.length
                    ? _AlbumSlot(album: favorites[i], uid: uid, index: i, titled: true)
                    : _EmptySlot(onTap: onPickAlbums),
            ],
          ),
          const SizedBox(height: 20),
          _FavLabel(label: l.favoritesArtistsLabel, onPick: onPickArtists, pickKey: 'pick-artists'),
          const SizedBox(height: 8),
          _Row3(
            gap: 8,
            children: [
              for (var i = 0; i < UserRepo.maxFavorites; i++)
                i < artists.length
                    ? _ArtistSlot(artist: artists[i], index: i)
                    : _EmptySlot(onTap: onPickArtists, circle: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Los favoritos de otra persona: sus tres discos en rejilla (separación 2,
/// sin títulos) y, debajo, sus artistas.
class _TheirFavorites extends StatelessWidget {
  const _TheirFavorites({required this.favorites, required this.artists, required this.uid});

  final List<Album> favorites;
  final List<Artist> artists;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (favorites.isEmpty && artists.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (favorites.isNotEmpty)
            _Row3(
              gap: 2,
              children: [
                for (var i = 0; i < UserRepo.maxFavorites; i++)
                  i < favorites.length
                      ? _AlbumSlot(album: favorites[i], uid: uid, index: i, titled: false)
                      : const SizedBox.shrink(),
              ],
            ),
          if (artists.isNotEmpty) ...[
            SizedBox(height: favorites.isEmpty ? 0 : 20),
            _FavLabel(label: l.favoritesArtistsLabel),
            const SizedBox(height: 8),
            _Row3(
              gap: 8,
              children: [
                for (var i = 0; i < UserRepo.maxFavorites; i++)
                  i < artists.length ? _ArtistSlot(artist: artists[i], index: i) : const SizedBox.shrink(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tres columnas iguales.
class _Row3 extends StatelessWidget {
  const _Row3({required this.children, required this.gap});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _AlbumSlot extends StatelessWidget {
  const _AlbumSlot({
    required this.album,
    required this.uid,
    required this.index,
    required this.titled,
  });

  final Album album;
  final String uid;
  final int index;
  final bool titled;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'fav-$uid-${album.id}';
    return GestureDetector(
      key: ValueKey('fav-album-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openAlbum(context, album, heroTag: heroTag),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumCover(url: album.smallCover, heroTag: heroTag),
          if (titled) ...[
            const SizedBox(height: 6),
            Text(
              album.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: VText.ui(13, weight: 600),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtistSlot extends StatelessWidget {
  const _ArtistSlot({required this.artist, required this.index});

  final Artist artist;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('fav-artist-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openArtist(context, artist),
      child: Column(
        children: [
          ArtistAvatar(artist: artist),
          const SizedBox(height: 8),
          Text(
            artist.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: VText.ui(13, weight: 600),
          ),
        ],
      ),
    );
  }
}

/// Un hueco sin favorito en el perfil propio: cuadro (o círculo) con borde
/// y un + que abre el selector.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap, this.circle = false});

  final VoidCallback? onTap;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(color: pressed ? c.ink : c.lineStrong),
          ),
          alignment: Alignment.center,
          child: onTap == null ? null : VIconView(VIcon.plus, size: 18, color: c.ink4),
        ),
      ),
    );
  }
}

/// "Cómo califico · Promedio 8,3": el histograma de sus notas (56, en
/// énfasis) con los números del 1 al 10.
class _HowIRate extends StatelessWidget {
  const _HowIRate({required this.ratings, required this.isMe});

  final List<RatingEntry> ratings;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final average = ratings.fold<int>(0, (s, r) => s + r.score) / ratings.length;
    final hist = {
      for (var i = 1; i <= 10; i++) i: ratings.where((r) => r.score == i).length,
    };
    return Padding(
      key: const ValueKey('profile-how'),
      padding: const EdgeInsets.fromLTRB(VSpace.page, 26, VSpace.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: VMono(isMe ? l.profileHowIRate : l.profileHowTheyRate)),
              VMono(l.profileAverageLabel(Score.formatAverage(average, l.localeName))),
            ],
          ),
          const SizedBox(height: 10),
          Histogram10(counts: hist, height: 56),
          const SizedBox(height: 6),
          const RulerNumbers(),
        ],
      ),
    );
  }
}
