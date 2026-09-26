import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/affinity.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/share_links.dart';
import '../widgets/album_cover.dart';
import '../widgets/follow_button.dart';
import '../widgets/pull_stretch.dart';
import '../services/services.dart';
import '../share_cards/share_card_data.dart';
import '../share_cards/share_specs.dart';
import '../widgets/share_button.dart';
import '../widgets/share_sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// Alto del banner debajo de la barra de estado (156 en el prototipo, con
/// sus 54 de barra de estado).
const double profileBannerBelowStatus = 102;

/// Encabezado del perfil: el banner (su foto o una franja del color de la
/// persona) con los botones encima, el avatar de 88 montado 44 sobre él, el
/// nombre en 50, "@usuario · te sigue", la biografía, el botón de seguir (en
/// el ajeno), las cuatro cifras y, en el ajeno, la afinidad musical. Con
/// `scroll`, al tirar hacia abajo estando arriba el banner crece y los
/// botones de encima se quedan quietos.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isMe,
    required this.standalone,
    required this.ratings,
    this.mine,
    this.followsMe,
    this.scroll,
  });

  final UserProfile profile;
  final bool isMe;

  /// Abierto como ruta propia: lleva volver.
  final bool standalone;

  /// Las notas de la persona (null mientras cargan).
  final List<RatingEntry>? ratings;

  /// Mis notas, para la afinidad (solo en el ajeno).
  final Future<List<RatingEntry>>? mine;

  /// Si la persona me sigue (solo en el ajeno).
  final Stream<bool>? followsMe;

  /// El desplazamiento de la pantalla, para estirar el banner.
  final ScrollController? scroll;

  /// Mi perfil (y mi semana) o, en el de otra persona, nuestra
  /// compatibilidad si tenemos discos en común. Sin eso, solo el enlace.
  Future<List<ShareCardSpec>> _shareCards(BuildContext context) async {
    final theirs = ratings;
    final accent = ShareSpecs.accentOf(context);
    final me = CurrentUser.maybeOf(context);
    if (theirs == null || me == null) return const [];
    if (isMe) return ShareSpecs.myProfile(profile, theirs, accent: accent);
    final mineList = await mine;
    if (mineList == null) return const [];
    final affinity = affinityBetween(mineList, theirs);
    return ShareSpecs.friend(
      friendCardFrom(
        percent: affinity.percent,
        albums: affinity.albums,
        me: CardPerson.fromProfile(me),
        friend: CardPerson.fromProfile(profile),
      ),
      accent: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final topPad = MediaQuery.paddingOf(context).top;
    final bannerHeight = topPad + profileBannerBelowStatus;
    final bio = (profile.bio ?? '').trim();
    final scroll = this.scroll;
    // Volver, compartir y configuración; al tirar hacia abajo no bajan.
    final buttons = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (standalone)
            VIconButton(
              key: const ValueKey('back'),
              icon: VIcon.back,
              style: VIconButtonStyle.filled,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          const Spacer(),
          ShareButton(
            key: const ValueKey('share-profile'),
            message: (l) => shareProfileMessage(profile, l, mine: isMe),
            cards: () => _shareCards(context),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            VIconButton(
              key: const ValueKey('settings'),
              icon: VIcon.settings,
              style: VIconButtonStyle.filled,
              tooltip: l.settingsTitle,
              onTap: () => openSettings(context),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El banner y el avatar, que asoma 44 por debajo de él (88 más el
        // anillo de 4 del color de fondo).
        SizedBox(
          height: bannerHeight + 96 - 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: bannerHeight,
                child: scroll == null
                    ? _Banner(profile: profile)
                    : PullStretch(controller: scroll, height: bannerHeight, child: _Banner(profile: profile)),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: topPad + 4,
                child: scroll == null ? buttons : PullPinned(controller: scroll, child: buttons),
              ),
              Positioned(
                left: VSpace.page,
                top: bannerHeight - 44,
                child: UserAvatar(
                  name: profile.name,
                  color: profile.color,
                  url: profile.avatarUrl,
                  size: 88,
                  ring: true,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                profile.name,
                key: const ValueKey('profile-name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VText.display(50, weight: 800, height: 0.9, tracking: 0),
              ),
              if (profile.username != null) ...[
                const SizedBox(height: 6),
                StreamBuilder<bool>(
                  stream: followsMe,
                  builder: (context, snap) => VMono(
                    snap.data == true
                        ? '${profile.handle} · ${l.profileFollowsYou}'
                        : profile.handle,
                    key: const ValueKey('profile-handle'),
                    maxLines: 1,
                  ),
                ),
              ],
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  bio,
                  key: const ValueKey('profile-bio'),
                  style: VText.ui(14.5, height: 1.4, color: c.inkA(0.78)),
                ),
              ],
              if (!isMe) ...[
                const SizedBox(height: 16),
                FollowButton(person: profile.person, testKey: 'follow-profile'),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(VSpace.page, isMe ? 16 : 18, VSpace.page, 0),
          child: _Stats(profile: profile, ratings: ratings),
        ),
        if (!isMe) _Affinity(theirs: ratings, mine: mine),
      ],
    );
  }
}

/// La foto de fondo o, sin ella, una franja del color de la persona.
class _Banner extends StatelessWidget {
  const _Banner({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final shade = VColors.of(context).coverShade(profile.color, lightness: 0.35);
    final url = profile.bannerUrl;
    return ColoredBox(
      color: shade,
      child: url == null
          ? null
          : Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
    );
  }
}

/// Discos, promedio, seguidores y seguidos, en cuatro columnas con líneas.
/// Seguidores y seguidos abren su lista.
class _Stats extends StatelessWidget {
  const _Stats({required this.profile, required this.ratings});

  final UserProfile profile;
  final List<RatingEntry>? ratings;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final list = ratings;
    final count = list?.length;
    final average = list == null || list.isEmpty
        ? null
        : list.fold<int>(0, (s, r) => s + r.score) / list.length;

    Widget cell({
      required String value,
      required String label,
      bool first = false,
      Key? key,
      VoidCallback? onTap,
    }) {
      final content = Container(
        padding: EdgeInsets.fromLTRB(first ? 0 : 10, 10, 0, 10),
        decoration: first
            ? null
            : BoxDecoration(border: Border(left: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              style: VText.display(28, weight: 700, stretch: 65, height: 1, tracking: 0),
            ),
            const SizedBox(height: 4),
            VMono(label, size: 9.5, maxLines: 1),
          ],
        ),
      );
      return Expanded(
        child: onTap == null
            ? content
            : Pressable(
                key: key,
                onTap: onTap,
                builder: (context, pressed) => Opacity(opacity: pressed ? 0.6 : 1, child: content),
              ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              value: count == null ? '—' : '$count',
              label: l.statAlbums(count ?? 0),
              first: true,
            ),
            cell(
              value: average == null ? '—' : Score.formatAverage(average, l.localeName),
              label: l.statAverage,
            ),
            cell(
              key: const ValueKey('followers'),
              value: '${profile.followersCount}',
              label: l.followersWord(profile.followersCount),
              onTap: () => openFollowList(context, uid: profile.uid, name: profile.name, followers: true),
            ),
            cell(
              key: const ValueKey('following'),
              value: '${profile.followingCount}',
              label: l.followingWord(profile.followingCount),
              onTap: () => openFollowList(context, uid: profile.uid, name: profile.name, followers: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// "95 %" en 80 con "Afinidad musical" y "Según N discos en común".
class _Affinity extends StatelessWidget {
  const _Affinity({required this.theirs, required this.mine});

  final List<RatingEntry>? theirs;
  final Future<List<RatingEntry>>? mine;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return FutureBuilder<List<RatingEntry>>(
      future: mine,
      builder: (context, snap) {
        final mineList = snap.data;
        final theirList = theirs;
        final result = mineList == null || theirList == null
            ? null
            : affinityBetween(mineList, theirList);
        final percent = result?.percent;
        final albums = result?.albums ?? const <CommonAlbum>[];
        return Padding(
          key: const ValueKey('affinity'),
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    percent == null ? '—' : '$percent%',
                    style: VText.display(
                      80,
                      weight: 800,
                      height: 0.8,
                      tracking: 0,
                      color: percent == null ? c.inkA(0.28) : c.accentText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VMono(l.affinity, color: c.accentText),
                        const SizedBox(height: 4),
                        Text(
                          result == null
                              ? ''
                              : percent == null
                                  ? l.affinityNone
                                  : l.affinityBasis(result.common),
                          style: VText.ui(13.5, color: c.ink2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (albums.isNotEmpty) ...[
                const SizedBox(height: 12),
                CommonAlbumsRow(albums: albums),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Los discos en común con la otra persona en miniatura: portadas de 40 con
/// separación de 2, hasta 6; si hay más, una última celda "+N". Tocar una
/// abre el disco. Si no caben todas a lo ancho, se muestran las que caben.
class CommonAlbumsRow extends StatelessWidget {
  const CommonAlbumsRow({super.key, required this.albums});

  final List<CommonAlbum> albums;

  static const double size = 40;
  static const double gap = 2;
  static const int maxShown = 6;

  /// Cuántas portadas se ven y cuántas quedan para "+N" en `cells` celdas.
  static ({int shown, int more}) layout(int total, int cells) {
    if (total <= math.min(maxShown, cells)) return (shown: total, more: 0);
    final shown = math.max(0, math.min(maxShown, cells - 1));
    return (shown: shown, more: total - shown);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cells = ((constraints.maxWidth + gap) / (size + gap)).floor();
        final (:shown, :more) = layout(albums.length, cells);
        return Row(
          key: const ValueKey('common-albums'),
          children: [
            for (var i = 0; i < shown; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _cover(context, i),
            ],
            if (more > 0) ...[
              if (shown > 0) const SizedBox(width: gap),
              Container(
                key: const ValueKey('common-more'),
                width: size,
                height: size,
                alignment: Alignment.center,
                color: c.surface,
                child: VMono('+$more', size: 10, tracking: 0.04, color: c.ink2, maxLines: 1),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _cover(BuildContext context, int i) {
    final album = albums[i].album;
    final heroTag = 'common-${album.id}';
    return GestureDetector(
      key: ValueKey('common-album-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openAlbum(context, album, heroTag: heroTag),
      child: AlbumCover(url: album.smallCover, size: size, heroTag: heroTag),
    );
  }
}

/// Lo que queda fijo arriba al bajar: el nombre en 40 con "N discos ·
/// promedio" y las pestañas.
class ProfileCompactBar extends StatelessWidget {
  const ProfileCompactBar({
    super.key,
    required this.profile,
    required this.ratings,
    required this.tabs,
  });

  final UserProfile profile;
  final List<RatingEntry>? ratings;
  final Widget tabs;

  /// Del borde de arriba (bajo la barra de estado) a las pestañas: 8 de
  /// aire, la fila del nombre (40 × 0,85) y 14.
  static const double tabsOffset = 8 + 34 + 14;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final list = ratings ?? const <RatingEntry>[];
    final average = list.isEmpty
        ? null
        : list.fold<int>(0, (s, r) => s + r.score) / list.length;
    return Container(
      key: const ValueKey('profile-compact'),
      color: c.bg,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 8, VSpace.page, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.display(40, weight: 800, height: 0.85, tracking: 0),
                  ),
                ),
                const SizedBox(width: 12),
                VMono(
                  average == null
                      ? l.countAlbums(list.length)
                      : '${l.countAlbums(list.length)} · ${Score.formatAverage(average, l.localeName)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          tabs,
        ],
      ),
    );
  }
}
