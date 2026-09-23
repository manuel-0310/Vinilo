import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
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
    final title = widget.followers ? 'Seguidores' : 'Siguiendo';
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
                                ? (widget.isMe ? 'Cargando…' : widget.name)
                                : widget.followers
                                    ? plural(people.length, 'persona sigue', 'personas siguen') +
                                        (widget.isMe ? ' tu diario' : ' a ${widget.name}')
                                    : (widget.isMe
                                        ? plural(people.length, 'persona seguida', 'personas seguidas')
                                        : '${widget.name} sigue a ${plural(people.length, 'persona', 'personas')}'),
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
                        title: widget.followers ? 'Nadie todavía' : 'A nadie todavía',
                        message: widget.followers
                            ? (widget.isMe
                                ? 'Cuando alguien te siga, aparecerá aquí.'
                                : 'Nadie sigue a ${widget.name} todavía.')
                            : (widget.isMe
                                ? 'Busca a tus amigos en la pestaña Buscar y sigue su diario.'
                                : '${widget.name} no sigue a nadie todavía.'),
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
