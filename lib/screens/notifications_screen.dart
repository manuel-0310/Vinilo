import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/notification.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/format.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// Notificaciones de la más reciente a la más antigua, agrupadas por día
/// (Hoy, Ayer, Esta semana, luego mes y año). Al abrirla se marcan todas
/// como leídas; las que estaban sin leer llevan su punto de énfasis hasta
/// salir. Deslizar a la izquierda borra una; "Borrar todas" pide
/// confirmación.
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
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.notificationsClearTitle,
      message: l.notificationsClearBody,
      confirmLabel: l.notificationsClear,
      danger: true,
      confirmKey: const ValueKey('notifications-clear-confirm'),
    );
    if (!ok || !mounted) return;
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
    final l = context.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<AppNotification>>(
          stream: _stream,
          builder: (context, snap) {
            final items = snap.data?.where((n) => !_removed.contains(n.id)).toList();
            if (items != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _markRead(items);
              });
            }
            final unread = _wasUnread ??
                {for (final n in items ?? const <AppNotification>[]) if (!n.read) n.id};
            final unreadLeft = items?.where((n) => unread.contains(n.id)).length ?? 0;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: VPageHeader(
                    title: l.notificationsTitle,
                    subtitle: items == null
                        ? l.loading
                        : unreadLeft == 0
                            ? l.notificationsAllCaughtUp
                            : l.notificationsUnread(unreadLeft),
                    subtitleKey: const ValueKey('notifications-subtitle'),
                    action: items != null && items.isNotEmpty ? l.notificationsClear : null,
                    onAction: items == null ? null : () => _deleteAll(items),
                    actionKey: const ValueKey('notifications-clear'),
                  ),
                ),
                if (snap.hasError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                      child: Text(
                        l.notificationsError(describeError(snap.error, l)),
                        style: VText.ui(13, color: c.danger),
                      ),
                    ),
                  )
                else if (items == null)
                  const _Skeleton()
                else if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                      child: VEmptyState(
                        title: l.notificationsEmptyTitle,
                        message: l.notificationsEmptyBody,
                      ),
                    ),
                  )
                else
                  for (final group in _groups(items, l))
                    SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(child: _GroupHeader(group.label)),
                        SliverList.builder(
                          itemCount: group.items.length,
                          itemBuilder: (context, i) {
                            final (index, n) = group.items[i];
                            return Dismissible(
                              key: ValueKey('dismiss-${n.id}'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _delete(n),
                              background: Container(
                                color: c.danger,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                                child: VIconView(VIcon.trash, size: 20, color: c.onAccent),
                              ),
                              child: _NotificationRow(
                                key: ValueKey('notification-$index'),
                                item: n,
                                fresh: unread.contains(n.id),
                                onTap: () => _open(n),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Las notificaciones (ya de la más reciente a la más antigua) en grupos
  /// seguidos por día, con su posición en la lista completa para las
  /// llaves de prueba.
  List<_Group> _groups(List<AppNotification> items, AppLocalizations l) {
    final now = DateTime.now();
    final groups = <_Group>[];
    for (final (i, n) in items.indexed) {
      final label = dayGroup(n.createdAt, l, now: now);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_Group(label, []));
      }
      groups.last.items.add((i, n));
    }
    return groups;
  }
}

class _Group {
  _Group(this.label, this.items);

  final String label;
  final List<(int, AppNotification)> items;
}

/// "AYER": etiqueta mono con la línea de arriba.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: VMono(label),
    );
  }
}

/// Una notificación: avatar de 36, la frase (14,5) con quien la provocó y el
/// disco o la lista en negrita, la hora en mono y, si estaba sin leer, un
/// punto de énfasis. Las leídas van al 78 %.
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
    final l = context.l10n;
    final bold = VText.ui(14.5, weight: 700, color: c.ink, height: 1.35);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : c.bg,
          border: Border(top: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => openUser(context, item.from.uid),
              child: UserAvatar(
                name: item.from.name,
                color: Color(item.from.colorValue),
                url: item.from.avatarUrl,
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        for (final (text, strong) in item.parts(l))
                          TextSpan(text: text, style: strong ? bold : null),
                      ],
                    ),
                    style: VText.ui(14.5, height: 1.35, color: fresh ? c.ink : c.inkA(0.78)),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  VMono(timeAgo(item.createdAt, l), size: 10, tracking: 0.06, color: c.ink4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox.square(
              dimension: 8,
              child: fresh
                  ? DecoratedBox(
                      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 12),
        child: Row(
          children: [
            VSkeleton(width: 36, height: 36, circle: true),
            SizedBox(width: 12),
            Expanded(child: VSkeleton(height: 34)),
          ],
        ),
      ),
    );
  }
}
