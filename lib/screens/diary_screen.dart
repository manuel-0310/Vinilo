import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/search_text.dart';
import '../widgets/diary_row.dart';
import '../widgets/misc.dart';

enum DiarySort { date, score }

/// Diario completo de una persona: buscar por disco o artista, filtrar por
/// nota y ordenar por fecha o por nota.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.isMe,
    required this.initial,
  });

  final String uid;
  final String name;
  final bool isMe;
  final List<RatingEntry> initial;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _controller = TextEditingController();
  Stream<List<RatingEntry>>? _stream;
  String _query = '';
  int? _score;
  DiarySort _sort = DiarySort.date;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= ServicesScope.of(context).ratings.userRatings(widget.uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<RatingEntry> _filter(List<RatingEntry> all) {
    final out = all.where((e) {
      if (_score != null && e.score != _score) return false;
      return albumMatches(e.album, _query);
    }).toList();
    if (_sort == DiarySort.score) {
      out.sort((a, b) {
        final c = b.score.compareTo(a.score);
        return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
      });
    } else {
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<RatingEntry>>(
            stream: _stream,
            initialData: widget.initial,
            builder: (context, snap) {
              final all = snap.data ?? widget.initial;
              final shown = _filter(all);
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 62, VSpace.page, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isMe ? context.l10n.diaryMine : context.l10n.diaryOf(widget.name),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: VText.display(38, height: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.countRatedAlbums(all.length),
                            style: VText.ui(13, color: c.text2),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const ValueKey('diary-search'),
                            controller: _controller,
                            textInputAction: TextInputAction.search,
                            onChanged: (v) => setState(() => _query = v),
                            style: VText.ui(16, weight: 600),
                            decoration: InputDecoration(
                              hintText: context.l10n.diarySearchHint,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: c.text3,
                              ),
                              suffixIcon: _controller.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: c.text3,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: _Filters(
                        score: _score,
                        sort: _sort,
                        onScore: (v) => setState(() => _score = v),
                        onSort: (v) => setState(() => _sort = v),
                      ),
                    ),
                  ),
                  if (shown.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        title: context.l10n.searchNothingTitle,
                        message: context.l10n.diaryNoMatch,
                      ),
                    )
                  else
                    DiaryList(entries: shown, grouped: _sort == DiarySort.date),
                  SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
                ],
              );
            },
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
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.score,
    required this.sort,
    required this.onScore,
    required this.onSort,
  });

  final int? score;
  final DiarySort sort;
  final ValueChanged<int?> onScore;
  final ValueChanged<DiarySort> onSort;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
            children: [
              ChoicePill(
                key: const ValueKey('diary-filter-all'),
                label: context.l10n.filterAll,
                selected: score == null,
                onTap: () => onScore(null),
              ),
              for (var n = 10; n >= 1; n--) ...[
                const SizedBox(width: 8),
                ChoicePill(
                  key: ValueKey('diary-filter-$n'),
                  label: '$n',
                  selected: score == n,
                  color: c.score(n),
                  onTap: () => onScore(score == n ? null : n),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
          child: Row(
            children: [
              Text(context.l10n.sortBy, style: VText.label(11, color: c.text3)),
              const SizedBox(width: 12),
              ChoicePill(
                key: const ValueKey('diary-sort-date'),
                label: context.l10n.sortDate,
                selected: sort == DiarySort.date,
                onTap: () => onSort(DiarySort.date),
              ),
              const SizedBox(width: 8),
              ChoicePill(
                key: const ValueKey('diary-sort-score'),
                label: context.l10n.sortScore,
                selected: sort == DiarySort.score,
                onTap: () => onSort(DiarySort.score),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
