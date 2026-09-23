import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/notification.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/format.dart';
import '../widgets/album_cover.dart';
import '../widgets/misc.dart';
import '../widgets/user_avatar.dart';
import 'routes.dart';

/// Notificaciones dentro de la app, de la más reciente a la más antigua.
/// Al abrirla se marcan todas como leídas; las que estaban sin leer se
/// distinguen hasta salir.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<AppNotification>>? _stream;
  Set<String>? _wasUnread;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    final me = CurrentUser.of(context);
    _stream = ServicesScope.of(context).notifications.watch(me.uid);
  }

  void _markRead(List<AppNotification> items) {
    // Solo la primera vez: se recuerda cuáles estaban sin leer para
    // pintarlas distinto, y se marcan todas como leídas.
    if (_wasUnread != null) return;
    _wasUnread = {for (final n in items) if (!n.read) n.id};
    if (_wasUnread!.isNotEmpty) {
      ServicesScope.of(context).notifications.markRead(items);
    }
  }

  void _open(AppNotification n) {
    switch (n.type) {
      case NotificationType.follow:
        openUser(context, n.from.uid);
      case NotificationType.likeRating:
        final album = n.album;
        if (album != null) {
          openAlbum(context, album, heroTag: 'notif-${n.id}');
        }
      case NotificationType.likeList:
      case NotificationType.saveList:
        final id = n.listId;
        if (id != null) openList(context, listId: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<AppNotification>>(
            stream: _stream,
            builder: (context, snap) {
              final items = snap.data;
              if (items != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _markRead(items);
                });
              }
              final unread = _wasUnread ?? {for (final n in items ?? const <AppNotification>[]) if (!n.read) n.id};
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 62, VSpace.page, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notificaciones', style: VText.display(38, height: 1)),
                          const SizedBox(height: 4),
                          Text(
                            items == null
                                ? 'Cargando…'
                                : unread.isEmpty
                                    ? 'Todo al día'
                                    : plural(unread.length, 'nueva', 'nuevas'),
                            key: const ValueKey('notifications-subtitle'),
                            style: VText.ui(13, color: c.text2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  if (snap.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                        child: Text(
                          'No se pudieron cargar: ${snap.error}',
                          style: VText.ui(13, color: c.danger),
                        ),
                      ),
                    )
                  else if (items == null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                      sliver: SliverList.separated(
                        itemCount: 5,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, _) => const Skeleton(height: 60, radius: 14),
                      ),
                    )
                  else if (items.isEmpty)
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'Nada por ahora',
                        message:
                            'Aquí verás cuando alguien te siga, le guste una de tus notas o guarde una de tus listas.',
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => _NotificationRow(
                        key: ValueKey('notification-$i'),
                        item: items[i],
                        fresh: unread.contains(items[i].id),
                        onTap: () => _open(items[i]),
                      ).animate().fadeIn(delay: (25 * (i % 12)).ms, duration: 300.ms),
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.item,
    required this.fresh,
    required this.onTap,
  });

  final AppNotification item;

  /// Estaba sin leer al abrir la pantalla.
  final bool fresh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final name = item.from.name;
    final rest = item.text.startsWith(name)
        ? item.text.substring(name.length)
        : item.text.replaceFirst(name, '');
    final prefix = item.text.startsWith(name)
        ? ''
        : item.text.substring(0, item.text.indexOf(name).clamp(0, item.text.length));
    Widget? trailing;
    switch (item.type) {
      case NotificationType.likeRating:
        trailing = AlbumCover(url: item.album?.smallCover, size: 44, radius: 9);
      case NotificationType.likeList:
      case NotificationType.saveList:
        trailing = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            item.type == NotificationType.likeList
                ? Icons.favorite_rounded
                : Icons.bookmark_rounded,
            size: 20,
            color: c.text2,
          ),
        );
      case NotificationType.follow:
        trailing = null;
    }
    return Material(
      color: fresh ? c.accent.withValues(alpha: 0.07) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => openUser(context, item.from.uid),
                child: UserAvatar(
                  name: item.from.name,
                  color: Color(item.from.colorValue),
                  url: item.from.avatarUrl,
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          if (prefix.isNotEmpty) TextSpan(text: prefix),
                          TextSpan(text: name, style: VText.ui(14, weight: 800)),
                          TextSpan(text: rest),
                        ],
                      ),
                      style: VText.ui(14, height: 1.35),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(timeAgo(item.createdAt), style: VText.ui(11, color: c.text3)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
              if (fresh) ...[
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
