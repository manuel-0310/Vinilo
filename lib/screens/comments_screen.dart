import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/ranking.dart';
import '../widgets/album_cover.dart';
import '../widgets/comment_card.dart';
import '../widgets/misc.dart';

/// Todos los comentarios de un disco (las notas con texto), con más "me
/// gusta" primero.
class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.album, required this.initial});

  final Album album;
  final List<RatingEntry> initial;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  Stream<List<RatingEntry>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= ServicesScope.of(context).ratings.albumRatings(widget.album.id);
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
              final comments = topComments(snap.data ?? widget.initial);
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        VSpace.page,
                        topPad + 62,
                        VSpace.page,
                        0,
                      ),
                      child: Row(
                        children: [
                          AlbumCover(
                            url: widget.album.smallCover,
                            size: 64,
                            radius: 12,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.commentsTitle,
                                  style: VText.display(34, height: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.album.name} · ${context.l10n.countComments(comments.length)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: VText.ui(13, color: c.text2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  if (comments.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        title: context.l10n.commentsEmptyTitle,
                        message: context.l10n.commentsEmptyBody,
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => CommentCard(
                        key: ValueKey('comment-$i'),
                        entry: comments[i],
                        maxLines: null,
                        index: i,
                      ).animate().fadeIn(delay: (40 * (i % 8)).ms),
                    ),
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
