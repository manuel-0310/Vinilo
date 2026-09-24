import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';

/// "Seguir" / "Siguiendo" para otra persona. Escucha el seguimiento en vivo
/// y no se muestra para uno mismo. `compact` es la versión de las filas.
class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    required this.person,
    this.compact = false,
    this.testKey,
  });

  final PersonInfo person;
  final bool compact;

  /// Llave para el driver de pruebas (`follow-<uid>`).
  final String? testKey;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  Stream<bool>? _stream;
  String? _me;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final me = CurrentUser.maybeOf(context);
    if (me == null || _me == me.uid) return;
    _me = me.uid;
    _stream = ServicesScope.of(context).follows.isFollowing(me.uid, widget.person.uid);
  }

  Future<void> _toggle(bool following) async {
    final me = CurrentUser.maybeOf(context);
    if (me == null || _busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      await ServicesScope.of(context).follows.setFollowing(
            me: me,
            other: widget.person,
            follow: !following,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSave(describeError(e, context.l10n)))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final me = CurrentUser.maybeOf(context);
    if (me == null || me.uid == widget.person.uid) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: _stream,
      builder: (context, snap) {
        final known = snap.hasData;
        final following = snap.data ?? false;
        final label = following ? context.l10n.following : context.l10n.follow;
        final bg = following ? c.surface2 : c.accent;
        final fg = following ? c.text : c.onAccent;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: known ? 1 : 0.4,
          child: Material(
            key: ValueKey(widget.testKey ?? 'follow-${widget.person.uid}'),
            color: bg,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: known && !_busy ? () => _toggle(following) : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : 18,
                  vertical: widget.compact ? 7 : 10,
                ),
                decoration: following
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: c.line),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (following) ...[
                      Icon(Icons.check_rounded, size: 15, color: fg),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      key: ValueKey(following ? 'following' : 'not-following'),
                      style: VText.ui(widget.compact ? 13 : 14, weight: 700, color: fg),
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
