import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/notification.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
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

  /// Las que se deslizaron o se borraron todas: salen de la lista al
  /// instante, sin esperar a que Firestore lo confirme (un `Dismissible`
  /// deslizado tiene que desaparecer del árbol en ese mismo cuadro).
  final Set<String> _removed = {};

  void _delete(AppNotification n) {
    HapticFeedback.lightImpact();
    setState(() => _removed.add(n.id));
    ServicesScope.of(context).notifications.delete(n.id);
  }

  Future<void> _deleteAll(List<AppNotification> items) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = VColors.of(ctx);
        return AlertDialog(
          title: Text(ctx.l10n.notificationsClearTitle, style: VText.display(28)),
          content: Text(
            ctx.l10n.notificationsClearBody,
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.cancel),
            ),
            TextButton(
              key: const ValueKey('notifications-clear-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.l10n.notificationsClear,
                style: VText.ui(14, weight: 700, color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).notifications;
    setState(() => _removed.addAll(items.map((n) => n.id)));
    await repo.deleteAll(me.uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    final me = CurrentUser.of(context);
    _stream = ServicesScope.of(context).notifications.watch(me.uid);
  }

  void _markRead(List<AppNotification> items) {
    // La primera vez se recuerda cuáles estaban sin leer, para pintarlas
    // distinto hasta salir. Todo lo que llegue sin leer mientras la pantalla
    // está abierta también se marca, para que la campana no vuelva a
    // encender el punto por algo que ya se vio.
    _wasUnread ??= {for (final n in items) if (!n.read) n.id};
    if (items.any((n) => !n.read)) {
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
      case NotificationType.reply:
      case NotificationType.mention:
        final id = n.ratingId;
        if (id != null) openThread(context, ratingId: id);
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
              final items = snap.data?.where((n) => !_removed.contains(n.id)).toList();
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.notificationsTitle,
                                  style: VText.display(38, height: 1),
                                ),
                              ),
                              if (items != null && items.isNotEmpty)
                                TextButton(
                                  key: const ValueKey('notifications-clear'),
                                  onPressed: () => _deleteAll(items),
                                  child: Text(
                                    context.l10n.notificationsClear,
                                    style: VText.ui(13, weight: 700, color: c.danger),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items == null
                                ? context.l10n.loading
                                : unread.isEmpty
                                    ? context.l10n.notificationsAllCaughtUp
                                    : context.l10n.notificationsNew(unread.length),
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
                          context.l10n.notificationsError(describeError(snap.error, context.l10n)),
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
                    SliverToBoxAdapter(
                      child: EmptyState(
                        title: context.l10n.notificationsEmptyTitle,
                        message: context.l10n.notificationsEmptyBody,
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => Dismissible(
                        key: ValueKey('dismiss-${items[i].id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(items[i]),
                        background: Container(
                          color: c.danger,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        child: _NotificationRow(
                          key: ValueKey('notification-$i'),
                          item: items[i],
                          fresh: unread.contains(items[i].id),
                          onTap: () => _open(items[i]),
                        ),
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
    final text = item.text(context.l10n);
    final rest = text.startsWith(name)
        ? text.substring(name.length)
        : text.replaceFirst(name, '');
    final prefix = text.startsWith(name)
        ? ''
        : text.substring(0, text.indexOf(name).clamp(0, text.length));
    Widget? trailing;
    switch (item.type) {
      case NotificationType.likeRating:
      case NotificationType.reply:
      case NotificationType.mention:
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
                    Text(timeAgo(item.createdAt, context.l10n), style: VText.ui(11, color: c.text3)),
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
