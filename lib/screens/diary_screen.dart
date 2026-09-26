import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/search_text.dart';
import '../widgets/diary_row.dart';
import '../widgets/line_field.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_ruler.dart';
import '../widgets/v_sections.dart';

enum DiarySort { date, score }

/// Diario completo de una persona ("Ver todo" del perfil): buscar por disco
/// o artista, filtrar por nota con la regla del 1 al 10 y ordenar por fecha
/// (agrupado por mes) o por nota.
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
    final l = context.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    Widget option(String key, String label, bool selected, VoidCallback? onTap) => Pressable(
          key: ValueKey(key),
          onTap: onTap,
          builder: (context, pressed) => Opacity(
            opacity: pressed ? 0.6 : 1,
            child: VMono(label, color: selected ? c.accentText : c.ink3),
          ),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<RatingEntry>>(
          stream: _stream,
          initialData: widget.initial,
          builder: (context, snap) {
            final all = snap.data ?? widget.initial;
            final shown = _filter(all);
            final filtering = _score != null || _query.trim().isNotEmpty;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: VPageHeader(
                    title: widget.isMe ? l.diaryMine : l.diaryOf(widget.name),
                    subtitle: l.countRatedAlbums(all.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LineField(
                          fieldKey: const ValueKey('diary-search'),
                          controller: _controller,
                          hint: l.diarySearchHint,
                          leading: VIconView(VIcon.search, size: 18, color: c.ink),
                          fontSize: 15,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textInputAction: TextInputAction.search,
                          onChanged: (v) => setState(() => _query = v),
                          trailing: _query.isEmpty
                              ? null
                              : Pressable(
                                  onTap: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                  builder: (context, pressed) => Opacity(
                                    opacity: pressed ? 0.5 : 1,
                                    child: VIconView(VIcon.close, size: 14, color: c.inkA(0.6)),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(child: VMono(l.diaryFilterScore)),
                            option(
                              'diary-filter-all',
                              l.filterAll,
                              _score != null,
                              _score == null ? null : () => setState(() => _score = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RulerCells(
                          selected: _score,
                          lines: true,
                          keyPrefix: 'diary-filter',
                          onTap: (k) => setState(() => _score = _score == k ? null : k),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 10),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: Row(
                      children: [
                        Expanded(
                          child: VMono(
                            filtering
                                ? l.listsShowing(shown.length, all.length)
                                : l.countRatedAlbums(all.length),
                            maxLines: 1,
                          ),
                        ),
                        option('diary-sort-date', l.sortDate, _sort == DiarySort.date,
                            () => setState(() => _sort = DiarySort.date)),
                        const SizedBox(width: 14),
                        option('diary-sort-score', l.sortScore, _sort == DiarySort.score,
                            () => setState(() => _sort = DiarySort.score)),
                      ],
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverToBoxAdapter(
                    child: VEmptyState(
                      title: l.searchNothingTitle,
                      message: l.diaryNoMatch,
                    ),
                  )
                else
                  DiaryList(entries: shown, grouped: _sort == DiarySort.date),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
              ],
            );
          },
        ),
      ),
    );
  }
}
