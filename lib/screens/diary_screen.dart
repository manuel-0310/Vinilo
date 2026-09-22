import 'package:flutter/material.dart';

import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
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
    final q = _query.trim().toLowerCase();
    final out = all.where((e) {
      if (_score != null && e.score != _score) return false;
      if (q.isEmpty) return true;
      return e.album.name.toLowerCase().contains(q) ||
          e.album.artist.toLowerCase().contains(q);
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
                            widget.isMe ? 'Tu diario' : 'Diario de ${widget.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: VText.display(38, height: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plural(all.length, 'disco calificado', 'discos calificados'),
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
                              hintText: 'Disco o artista',
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
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'Nada por aquí',
                        message: 'Ningún disco del diario coincide con esa búsqueda o ese filtro.',
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
              _Chip(
                key: const ValueKey('diary-filter-all'),
                label: 'Todas',
                selected: score == null,
                onTap: () => onScore(null),
              ),
              for (var n = 10; n >= 1; n--) ...[
                const SizedBox(width: 8),
                _Chip(
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
              Text('ORDENAR POR', style: VText.label(11, color: c.text3)),
              const SizedBox(width: 12),
              _Chip(
                key: const ValueKey('diary-sort-date'),
                label: 'Fecha',
                selected: sort == DiarySort.date,
                onTap: () => onSort(DiarySort.date),
              ),
              const SizedBox(width: 8),
              _Chip(
                key: const ValueKey('diary-sort-score'),
                label: 'Nota',
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

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final accent = color ?? c.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.16) : c.surface2,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.7) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: VText.ui(13, weight: 700, color: selected ? accent : c.text2),
          ),
        ),
      ),
    );
  }
}
