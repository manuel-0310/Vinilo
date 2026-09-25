import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/v_sections.dart';
import '../widgets/person_row.dart';

/// Seguidores o seguidos de una persona: el encabezado de siempre y filas
/// de persona (avatar de 36, nombre, @usuario) con el botón de seguir.
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
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;
    final title = widget.followers ? l10n.followersTitle : l10n.following;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<PersonInfo>>(
          stream: _stream,
          builder: (context, snap) {
            final people = snap.data;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: VPageHeader(
                    title: title,
                    subtitle: people == null
                        ? (widget.isMe ? l10n.loading : widget.name)
                        : widget.followers
                            ? (widget.isMe
                                ? l10n.followersMine(people.length)
                                : l10n.followersOf(people.length, widget.name))
                            : (widget.isMe
                                ? l10n.followingMine(people.length)
                                : l10n.followingOf(people.length, widget.name)),
                  ),
                ),
                if (people == null)
                  SliverList.builder(
                    itemCount: 5,
                    itemBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
                      child: Row(
                        children: [
                          VSkeleton(width: 36, height: 36, circle: true),
                          SizedBox(width: 12),
                          Expanded(child: VSkeleton(height: 30)),
                        ],
                      ),
                    ),
                  )
                else if (people.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                      child: VEmptyState(
                        title: widget.followers ? l10n.followersEmptyTitle : l10n.followingEmptyTitle,
                        message: widget.followers
                            ? (widget.isMe
                                ? l10n.followersEmptyMine
                                : l10n.followersEmptyOf(widget.name))
                            : (widget.isMe
                                ? l10n.followingEmptyMine
                                : l10n.followingEmptyOf(widget.name)),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: people.length,
                    itemBuilder: (_, i) => PersonRow(
                      key: ValueKey('person-$i'),
                      person: people[i],
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
