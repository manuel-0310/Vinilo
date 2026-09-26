import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import 'v_buttons.dart';
import 'v_icons.dart';

/// "+ Seguir" (fondo de énfasis) o "✓ Siguiendo" (borde y texto en énfasis)
/// para otra persona. Escucha el seguimiento en vivo y no se muestra para
/// uno mismo. En el perfil va a lo ancho con 48 de alto; `compact` es la
/// versión de las filas de personas.
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
    final l = context.l10n;
    final me = CurrentUser.maybeOf(context);
    if (me == null || me.uid == widget.person.uid) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: _stream,
      builder: (context, snap) {
        final known = snap.hasData;
        final following = snap.data ?? false;
        final onTap = known && !_busy ? () => _toggle(following) : null;
        final label = Text(
          following ? l.following : l.followAction,
          key: ValueKey(following ? 'following' : 'not-following'),
          maxLines: 1,
          style: VText.ui(
            widget.compact ? 13 : 15,
            weight: 600,
            color: following ? c.accentText : c.onAccent,
          ),
        );
        return AnimatedOpacity(
          key: ValueKey(widget.testKey ?? 'follow-${widget.person.uid}'),
          duration: const Duration(milliseconds: 200),
          opacity: known ? 1 : 0.4,
          child: Pressable(
            onTap: onTap,
            builder: (context, pressed) => Container(
              height: widget.compact ? 32 : 48,
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 20),
              decoration: BoxDecoration(
                color: following ? null : (pressed ? c.ink : c.accent),
                border: following ? Border.all(color: pressed ? c.ink : c.accentText) : null,
              ),
              child: Row(
                mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (following) ...[
                    VIconView(VIcon.check, size: widget.compact ? 11 : 13, color: c.accentText),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: label),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
