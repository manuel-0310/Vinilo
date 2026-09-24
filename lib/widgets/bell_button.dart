import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/notification.dart';
import '../screens/routes.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';

/// Campana del inicio: abre las notificaciones y lleva un punto del color
/// de énfasis cuando hay alguna sin leer.
class BellButton extends StatefulWidget {
  const BellButton({super.key});

  @override
  State<BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<BellButton> {
  Stream<List<AppNotification>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    final me = CurrentUser.of(context);
    _stream = ServicesScope.of(context).notifications.watch(me.uid);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return StreamBuilder<List<AppNotification>>(
      stream: _stream,
      builder: (context, snap) {
        final unread = (snap.data ?? const <AppNotification>[]).any((n) => !n.read);
        return Tooltip(
          message: context.l10n.notificationsTitle,
          child: Material(
            color: c.surface2.withValues(alpha: 0.8),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('bell'),
              onTap: () => openNotifications(context),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 20, color: c.text),
                    if (unread)
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          key: const ValueKey('bell-dot'),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
