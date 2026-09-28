import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/affinity.dart';
import '../models/follow.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// Afinidad musical con otra persona: el porcentaje en 112, quién es y
/// "Según N discos en común"; las pestañas Todos / Coinciden / Discrepan con
/// cuántos hay; el orden ("Más parecidos primero" o "Más distintos
/// primero", se cambia tocándolo) y cada disco con mi nota y la suya.
class AffinityScreen extends StatefulWidget {
  const AffinityScreen({
    super.key,
    required this.person,
    required this.percent,
    required this.albums,
  });

  final PersonInfo person;
  final int percent;
  final List<CommonAlbum> albums;

  @override
  State<AffinityScreen> createState() => _AffinityScreenState();
}

class _AffinityScreenState extends State<AffinityScreen> {
  AffinityFilter _filter = AffinityFilter.all;
  bool? _desc;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final person = widget.person;
    final desc = _desc ?? affinityDefaultDesc(_filter);
    final rows = affinityView(widget.albums, _filter, mostDifferentFirst: desc);
    final firstName = person.name.trim().split(RegExp(r'\s+')).first;
    const filters = AffinityFilter.values;
    final labels = [l.affinityAll, l.affinityMatch, l.affinityDiffer];
    int countOf(AffinityFilter f) => widget.albums.where((a) => affinityIn(a, f)).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    VIconButton(
                      key: const ValueKey('back'),
                      icon: VIcon.back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VMono(l.affinity, color: c.accentText),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.percent}%',
                      key: const ValueKey('affinity-percent'),
                      style: VText.display(112, weight: 800, height: 0.78, tracking: -0.02, color: c.accentText),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => openUser(context, person.uid),
                      child: Row(
                        children: [
                          UserAvatar(
                            name: person.name,
                            color: Color(person.colorValue),
                            url: person.avatarUrl,
                            size: 22,
                            initialSize: 11,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              person.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(15, weight: 600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.affinityBasis(widget.albums.length),
                      style: VText.ui(13.5, color: c.ink2),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: VTabs(
                  labels: [
                    for (var i = 0; i < filters.length; i++) '${labels[i]} ${countOf(filters[i])}',
                  ],
                  keys: const ['affinity-all', 'affinity-match', 'affinity-differ'],
                  selected: filters.indexOf(_filter),
                  gap: 18,
                  onChanged: (i) => setState(() {
                    _filter = filters[i];
                    _desc = null;
                  }),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Pressable(
                          key: const ValueKey('affinity-sort'),
                          onTap: () => setState(() => _desc = !desc),
                          builder: (context, pressed) => Opacity(
                            opacity: pressed ? 0.6 : 1,
                            child: VMono(
                              '${desc ? l.affinityMostDifferent : l.affinityMostSimilar} ↓',
                              size: 10,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: _scoreColumn,
                      child: VMono(l.affinityYou, size: 10, color: c.accentText, align: TextAlign.center, maxLines: 1),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: _scoreColumn,
                      child: VMono(firstName, size: 10, color: c.ink4, align: TextAlign.center, maxLines: 1),
                    ),
                  ],
                ),
              ),
            ),
            if (rows.isEmpty)
              SliverToBoxAdapter(
                child: VEmptyState(
                  key: const ValueKey('affinity-empty'),
                  title: l.affinityEmptyTitle,
                  message: _filter == AffinityFilter.match ? l.affinityEmptyMatch : l.affinityEmptyDiffer,
                  padding: const EdgeInsets.fromLTRB(VSpace.page, 20, VSpace.page, 24),
                ),
              )
            else
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => _AffinityRow(key: ValueKey('affinity-row-$i'), album: rows[i]),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }
}

/// Ancho de las columnas "Tú" y la otra persona.
const double _scoreColumn = 40;

/// Un disco en común: portada de 44, título, "Artista · misma nota" (o "a N
/// puntos", en énfasis si es 1 o menos), mi nota en énfasis y la suya.
class _AffinityRow extends StatelessWidget {
  const _AffinityRow({super.key, required this.album});

  final CommonAlbum album;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final d = album.difference;
    final heroTag = 'affinity-${album.album.id}';
    final numberStyle = VText.display(30, weight: 700, height: 1, tracking: 0);
    return Pressable(
      onTap: () => openAlbum(context, album.album, heroTag: heroTag),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 9),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(top: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            AlbumCover(url: album.album.smallCover, size: 44, heroTag: heroTag),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(15, weight: 600),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${album.album.artist} · '),
                        TextSpan(
                          text: (d == 0 ? l.affinitySameScore : l.affinityPointsApart(d)).toUpperCase(),
                          style: VText.mono(10, tracking: 0.04, color: d <= 1 ? c.accentText : c.ink4),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(12.5, color: c.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: _scoreColumn,
              child: Text('${album.mine}', textAlign: TextAlign.center, style: numberStyle.copyWith(color: c.accentText)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: _scoreColumn,
              child: Text('${album.theirs}', textAlign: TextAlign.center, style: numberStyle),
            ),
          ],
        ),
      ),
    );
  }
}
