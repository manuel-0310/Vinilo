import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/notification.dart';
import '../screens/routes.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import 'v_buttons.dart';
import 'v_icons.dart';

/// Campana del inicio (22, sin borde): abre las notificaciones y lleva un
/// punto de énfasis de 8 con un anillo del color de fondo cuando hay alguna
/// sin leer.
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
        return VIconButton(
          key: const ValueKey('bell'),
          icon: VIcon.bell,
          style: VIconButtonStyle.plain,
          tooltip: context.l10n.notificationsTitle,
          onTap: () => openNotifications(context),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              VIconView(VIcon.bell, size: 22, color: c.ink),
              if (unread)
                // En el prototipo el punto (8 de color más 2 de anillo por
                // lado: 12) está a 7 del borde de arriba y a 8 del de la
                // derecha del botón de 40; la campana de 22 va centrada (9
                // por lado).
                Positioned(
                  top: 7 - 9,
                  right: 8 - 9,
                  child: Container(
                    key: const ValueKey('bell-dot'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
