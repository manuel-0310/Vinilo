import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/misc.dart';
import '../widgets/person_row.dart';

/// Seguidores o seguidos de una persona, con el botón de seguir en cada fila.
class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.isMe,
    required this.followers,
  });

  final String uid;
  final String name;
  final bool isMe;

  /// True: quiénes siguen a `uid`. False: a quiénes sigue.
  final bool followers;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  Stream<List<PersonInfo>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    final follows = ServicesScope.of(context).follows;
    _stream = widget.followers
        ? follows.followers(widget.uid)
        : follows.following(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;
    final title = widget.followers ? l10n.followersTitle : l10n.following;
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<PersonInfo>>(
            stream: _stream,
            builder: (context, snap) {
              final people = snap.data;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 62, VSpace.page, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: VText.display(38, height: 1)),
                          const SizedBox(height: 4),
                          Text(
                            people == null
                                ? (widget.isMe ? l10n.loading : widget.name)
                                : widget.followers
                                    ? (widget.isMe
                                        ? l10n.followersMine(people.length)
                                        : l10n.followersOf(people.length, widget.name))
                                    : (widget.isMe
                                        ? l10n.followingMine(people.length)
                                        : l10n.followingOf(people.length, widget.name)),
                            style: VText.ui(13, color: c.text2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  if (people == null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                      sliver: SliverList.separated(
                        itemCount: 5,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, _) => const Skeleton(height: 52, radius: 14),
                      ),
                    )
                  else if (people.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        title: widget.followers ? l10n.followersEmptyTitle : l10n.followingEmptyTitle,
                        message: widget.followers
                            ? (widget.isMe
                                ? l10n.followersEmptyMine
                                : l10n.followersEmptyOf(widget.name))
                            : (widget.isMe
                                ? l10n.followingEmptyMine
                                : l10n.followingEmptyOf(widget.name)),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: people.length,
                      itemBuilder: (_, i) => PersonRow(
                        key: ValueKey('person-$i'),
                        person: people[i],
                      ).animate().fadeIn(delay: (30 * (i % 10)).ms, duration: 320.ms),
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
