import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/oklch.dart';
import '../theme/vinilo_theme.dart';
import '../util/ranking.dart';
import '../widgets/comment_card.dart';
import '../widgets/v_sections.dart';

/// Todos los comentarios de un disco (las notas con texto), con más "me
/// gusta" primero, en las mismas filas que "Comentarios destacados".
class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.album, required this.initial});

  final Album album;
  final List<RatingEntry> initial;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  Stream<List<RatingEntry>>? _stream;

  /// El color de la portada (ya está en la caché si se viene del disco).
  Color? _coverColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    final services = ServicesScope.of(context);
    _stream = services.ratings.albumRatings(widget.album.id);
    services.palette
        .dominant(widget.album.smallCover ?? widget.album.bestCover)
        .then((color) {
      if (color != null && mounted) setState(() => _coverColor = color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final cover = _coverColor;
    final tone = cover == null ? c.accent : coverTone(cover);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<RatingEntry>>(
          stream: _stream,
          initialData: widget.initial,
          builder: (context, snap) {
            final comments = topComments(snap.data ?? widget.initial);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: VPageHeader(
                    title: l10n.commentsTitle,
                    subtitle: '${widget.album.name} · ${l10n.countComments(comments.length)}',
                  ),
                ),
                if (comments.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                      child: VEmptyState(
                        title: l10n.commentsEmptyTitle,
                        message: l10n.commentsEmptyBody,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(child: Container(height: 1, color: c.line)),
                        SliverList.builder(
                          itemCount: comments.length,
                          itemBuilder: (_, i) => CommentCard(
                            key: ValueKey('comment-$i'),
                            entry: comments[i],
                            maxLines: null,
                            index: i,
                            tone: tone,
                            last: i == comments.length - 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
              ],
            );
          },
        ),
      ),
    );
  }
}
