import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/music_list.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/line_field.dart';
import '../widgets/list_row_tile.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// La pestaña "Listas" del perfil: "Mías" y "Guardadas" (en el propio; en
/// el ajeno, solo "Listas") con cuántas hay, el buscador, los filtros en una
/// sola fila (una opción a la vez), "N listas · recientes ↓" (tocar el orden
/// pasa al siguiente) con "+ Nueva lista", y las filas.
class ProfileListsTab extends StatelessWidget {
  const ProfileListsTab({
    super.key,
    required this.owned,
    required this.saved,
    required this.isMe,
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
    final l = context.l10n;
    final viewingSaved = isMe && showSaved;
    final source = viewingSaved ? savedLists : mine;
    final shown = source == null ? null : applyListQuery(source, query);
    final keyPrefix = viewingSaved ? 'saved' : 'list';

    final sortLabels = {
      ListSort.recent: l.listsSortRecent,
      ListSort.name: l.listsSortName,
      ListSort.size: l.listsSortSize,
      ListSort.likes: l.listsSortLikes,
    };
    final filters = [
      (ListFilter.all, l.filterAll, 'lists-kind-all'),
      (ListFilter.lists, l.listsFilterLists, 'lists-kind-list'),
      (ListFilter.rankings, l.listsFilterRankings, 'lists-kind-ranking'),
      (ListFilter.tracks, l.listTypeTracks, 'lists-type-tracks'),
      (ListFilter.albums, l.listTypeAlbums, 'lists-type-albums'),
    ];
    final current = query.filter;

    final Widget body;
    if (shown == null) {
      body = Column(
        children: [
          for (var i = 0; i < 2; i++)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
              child: Row(
                children: [
                  VSkeleton(width: 88, height: 64),
                  SizedBox(width: 14),
                  Expanded(child: VSkeleton(height: 40)),
                ],
              ),
            ),
        ],
      );
    } else if (source!.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
        child: Text(
          viewingSaved
              ? l.listsSavedEmpty
              : isMe
                  ? l.listsEmptyMine
                  : l.listsEmptyTheirs,
          key: ValueKey('$keyPrefix-empty'),
          style: VText.ui(14, color: c.ink2, height: 1.45),
        ),
      );
    } else if (shown.isEmpty) {
      body = VEmptyState(
        key: const ValueKey('lists-no-match'),
        title: l.listsNoMatchTitle,
        message: l.listsNoMatchBody,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, list) in shown.indexed)
            ListRowTile(
              key: ValueKey('$keyPrefix-$i'),
              list: list,
              onTap: () => openList(context, listId: list.id, initial: list),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 20, VSpace.page, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: isMe
                ? [
                    _Heading(
                      key: const ValueKey('lists-mine'),
                      label: l.listsMine,
                      count: mine?.length,
                      selected: !viewingSaved,
                      onTap: () => onShowSaved(false),
                    ),
                    const SizedBox(width: 22),
                    _Heading(
                      key: const ValueKey('lists-saved'),
                      label: l.listsSaved,
                      count: savedLists?.length,
                      selected: viewingSaved,
                      onTap: () => onShowSaved(true),
                    ),
                  ]
                : [
                    _Heading(label: l.profileListsTab, count: mine?.length, selected: true),
                  ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 0),
          child: LineField(
            fieldKey: const ValueKey('lists-search'),
            controller: search,
            leading: VMono(l.listsSearchLabel),
            leadingGap: 10,
            hint: l.listsSearchPlaceholder,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(vertical: 10),
            textInputAction: TextInputAction.search,
            onChanged: (v) => onQuery(query.copyWith(text: v)),
            trailing: query.text.isEmpty
                ? null
                : Pressable(
                    key: const ValueKey('lists-clear'),
                    onTap: () {
                      search.clear();
                      onQuery(query.copyWith(text: ''));
                    },
                    builder: (context, pressed) => Opacity(
                      opacity: pressed ? 0.5 : 1,
                      child: VIconView(VIcon.close, size: 14, color: c.inkA(0.6)),
                    ),
                  ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 0),
          child: Row(
            children: [
              for (final (i, (filter, label, key)) in filters.indexed) ...[
                if (i > 0) const SizedBox(width: 18),
                _FilterOption(
                  key: ValueKey(key),
                  label: label,
                  selected: current == filter,
                  onTap: () => onQuery(query.withFilter(filter)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
          child: Row(
            children: [
              Flexible(
                child: VMono(
                  shown == null
                      ? ''
                      : query.filtering
                          ? '${l.listsShowing(shown.length, source!.length)} · '
                          : '${l.countLists(source!.length)} · ',
                  key: const ValueKey('lists-summary'),
                  maxLines: 1,
                ),
              ),
              Pressable(
                key: const ValueKey('lists-sort'),
                onTap: () => onQuery(query.copyWith(sort: nextListSort(query.sort))),
                builder: (context, pressed) => Opacity(
                  opacity: pressed ? 0.6 : 1,
                  child: VMono('${sortLabels[query.sort]!} ↓'),
                ),
              ),
              const Spacer(),
              if (isMe && !viewingSaved)
                Pressable(
                  key: const ValueKey('new-list'),
                  onTap: onNewList,
                  builder: (context, pressed) => Opacity(
                    opacity: pressed ? 0.6 : 1,
                    child: VMono(l.listNewPlus, color: c.accentText),
                  ),
                ),
            ],
          ),
        ),
        body,
      ],
    );
  }
}

/// "Mías²": el nombre en 30 condensado y la cifra en superíndice mono (en
/// énfasis si está elegida; las no elegidas van apagadas).
class _Heading extends StatelessWidget {
  const _Heading({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = selected ? c.ink : c.inkA(0.35);
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                count == null ? '' : '$count',
                style: VText.mono(11, tracking: 0, color: selected ? c.accentText : color),
              ),
            ),
          ),
        ],
      ),
      style: VText.display(30, weight: 700, stretch: 70, height: 1, tracking: 0, color: color),
    );
    if (onTap == null || selected) return text;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Opacity(opacity: pressed ? 0.6 : 1, child: text),
    );
  }
}

/// Un filtro: texto de 14; el elegido en tinta con una raya de 1 px debajo.
class _FilterOption extends StatelessWidget {
  const _FilterOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? c.ink : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: VText.ui(14, weight: 500, color: selected ? c.ink : c.inactive),
        ),
      ),
    );
  }
}
