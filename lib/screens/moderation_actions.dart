import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../models/moderation.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/menu_sheet.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';
import 'report_screen.dart';

/// Cómo se nombra a alguien en los menús y avisos: su @usuario o, si es una
/// cuenta de antes sin él, su nombre.
String handleOf(PersonInfo person) => person.handle.isEmpty ? person.name : person.handle;

/// El color del avatar de una cuenta bloqueada: gris, sin su color ni su
/// foto (tinta al 19 % sobre el fondo, el `#3a3836` del prototipo).
Color blockedAvatarColor(ViniloPalette c) => Color.alphaBlend(c.inkA(0.19), c.bg);

/// Abre "Reportar" para una persona o un comentario.
Future<void> openReport(
  BuildContext context, {
  required ReportTarget type,
  required String targetId,
  required PersonInfo target,
  String? ratingId,
  String excerpt = '',
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => ReportScreen(
        type: type,
        targetId: targetId,
        target: target,
        ratingId: ratingId,
        excerpt: excerpt,
      ),
    ),
  );
}

/// La hoja "¿Bloquear a @usuario?": explica qué pasa y, si se confirma,
/// bloquea. Devuelve true si quedó bloqueado.
Future<bool> confirmBlock(BuildContext context, PersonInfo person) async {
  final ok = await showVSheet<bool>(context, (_) => _BlockSheet(person: person));
  return ok ?? false;
}

class _BlockSheet extends StatefulWidget {
  const _BlockSheet({required this.person});

  final PersonInfo person;

  @override
  State<_BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends State<_BlockSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _block() async {
    if (_busy) return;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).moderation;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.block(me: me, other: widget.person);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.blockFailed(describeError(e, l));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final person = widget.person;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final rules = [l.blockRule1, l.blockRule2, l.blockRule3, l.blockRule4];
    return Container(
      key: const ValueKey('block-sheet'),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.buttonLine)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, math.max(38.0, bottomInset + 4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: UserAvatar(
                name: person.name,
                color: Color(person.colorValue),
                url: person.avatarUrl,
                size: 56,
                initialSize: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.blockTitle(handleOf(person)),
              style: VText.display(46, weight: 800, height: 0.9, tracking: 0),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Column(
                children: [
                  for (final (i, rule) in rules.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.lineSoft)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${i + 1}'.padLeft(2, '0'),
                                style: VText.mono(11, tracking: 0, color: c.ink4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(rule, style: VText.ui(15, height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(l.blockNote, style: VText.ui(12.5, height: 1.4, color: c.ink4)),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: VText.ui(13, height: 1.35, color: c.danger)),
            ],
            const SizedBox(height: 16),
            VPrimaryButton.tone(
              key: const ValueKey('block-confirm'),
              label: l.blockConfirm,
              color: c.danger,
              busy: _busy,
              onPressed: _block,
            ),
            const SizedBox(height: 8),
            VSecondaryButton(
              key: const ValueKey('block-cancel'),
              label: l.cancel,
              center: true,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que se puede hacer desde el "···" de un perfil ajeno.
enum ProfileMenuAction { share, mute, report, block, unblock }

/// El menú "···" del perfil de otra persona: Compartir perfil, Silenciar (o
/// dejar de silenciar), Reportar y Bloquear. En un perfil bloqueado, solo
/// Desbloquear y Reportar; `withShare` false quita "Compartir perfil".
/// Devuelve lo elegido; compartir y desbloquear los hace quien lo abre, lo
/// demás se resuelve aquí.
Future<ProfileMenuAction?> showProfileMenu(
  BuildContext context, {
  required PersonInfo person,
  bool blocked = false,
  bool withShare = true,
}) async {
  final l = context.l10n;
  final handle = handleOf(person);
  final moderation = Moderation.of(context);
  final muted = moderation.isMuted(person.uid);
  final choice = await showMenuSheet<ProfileMenuAction>(
    context,
    overline: handle,
    items: [
      if (blocked)
        MenuSheetItem(
          value: ProfileMenuAction.unblock,
          label: l.menuUnblockUser(handle),
          keyName: 'menu-unblock',
        )
      else ...[
        if (withShare)
          MenuSheetItem(
            value: ProfileMenuAction.share,
            label: l.menuShareProfile,
            keyName: 'menu-share',
          ),
        MenuSheetItem(
          value: ProfileMenuAction.mute,
          label: muted ? l.menuUnmute : l.menuMute,
          hint: muted ? l.menuUnmuteHint : l.menuMuteHint,
          keyName: 'menu-mute',
        ),
      ],
      MenuSheetItem(
        value: ProfileMenuAction.report,
        label: l.menuReportUser(handle),
        danger: true,
        keyName: 'menu-report',
      ),
      if (!blocked)
        MenuSheetItem(
          value: ProfileMenuAction.block,
          label: l.menuBlockUser(handle),
          danger: true,
          strong: true,
          keyName: 'menu-block',
        ),
    ],
  );
  if (choice == null || !context.mounted) return null;
  switch (choice) {
    case ProfileMenuAction.mute:
      await _toggleMute(context, person, muted: muted);
    case ProfileMenuAction.report:
      await openReport(context, type: ReportTarget.user, targetId: person.uid, target: person);
    case ProfileMenuAction.block:
      final done = await confirmBlock(context, person);
      if (done && context.mounted) _say(context, context.l10n.userBlocked(handle));
      return done ? ProfileMenuAction.block : null;
    case ProfileMenuAction.share:
    case ProfileMenuAction.unblock:
      break;
  }
  return choice;
}

Future<void> _toggleMute(BuildContext context, PersonInfo person, {required bool muted}) async {
  final me = CurrentUser.of(context);
  final repo = ServicesScope.of(context).moderation;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final handle = handleOf(person);
  try {
    if (muted) {
      await repo.unmute(me: me.uid, other: person.uid);
    } else {
      await repo.mute(me: me.uid, other: person);
    }
    HapticFeedback.selectionClick();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(muted ? l.userUnmuted(handle) : l.userMuted(handle)),
          duration: const Duration(seconds: 2),
        ),
      );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.couldNotSave(describeError(e, l)))));
  }
}

void _say(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
}

/// Lo que pasó con un comentario desde su menú "···".
enum ContentMenuResult { hidden, reported, blocked }

/// El menú "···" de una calificación o una respuesta ajena: Ocultar este
/// comentario (solo para mí, con "Deshacer"), Reportar comentario y
/// Bloquear a su autora. Devuelve lo que se hizo, o null.
Future<ContentMenuResult?> showContentMenu(
  BuildContext context, {
  required PersonInfo author,
  required ReportTarget kind,
  required String contentId,
  String? ratingId,
  String excerpt = '',
}) async {
  assert(kind.isContent);
  final l = context.l10n;
  final handle = handleOf(author);
  final choice = await showMenuSheet<ContentMenuResult>(
    context,
    overline: kind == ReportTarget.reply ? l.menuReplyOf(handle) : l.menuRatingOf(handle),
    items: [
      MenuSheetItem(
        value: ContentMenuResult.hidden,
        label: l.menuHideComment,
        hint: l.menuHideHint,
        keyName: 'menu-hide',
      ),
      MenuSheetItem(
        value: ContentMenuResult.reported,
        label: l.menuReportComment,
        danger: true,
        keyName: 'menu-report',
      ),
      MenuSheetItem(
        value: ContentMenuResult.blocked,
        label: l.menuBlockUser(handle),
        danger: true,
        strong: true,
        keyName: 'menu-block',
      ),
    ],
  );
  if (choice == null || !context.mounted) return null;
  switch (choice) {
    case ContentMenuResult.hidden:
      final me = CurrentUser.of(context);
      final repo = ServicesScope.of(context).moderation;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await repo.hide(me: me.uid, contentId: contentId, kind: kind, ratingId: ratingId);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(l.couldNotSave(describeError(e, l)))));
        return null;
      }
      HapticFeedback.selectionClick();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.commentHidden),
            duration: const Duration(seconds: 4),
            // Con acción, Flutter lo dejaría fijo hasta cerrarlo a mano.
            persist: false,
            action: SnackBarAction(
              key: const ValueKey('hide-undo'),
              label: l.undo,
              onPressed: () => repo.unhide(me: me.uid, contentId: contentId),
            ),
          ),
        );
      return ContentMenuResult.hidden;
    case ContentMenuResult.reported:
      await openReport(
        context,
        type: kind,
        targetId: contentId,
        target: author,
        ratingId: ratingId,
        excerpt: excerpt,
      );
      if (!context.mounted) return null;
      // Si se envió, quedó oculto.
      return Moderation.of(context).hidesContent(contentId) ? ContentMenuResult.reported : null;
    case ContentMenuResult.blocked:
      final done = await confirmBlock(context, author);
      if (done && context.mounted) _say(context, context.l10n.userBlocked(handle));
      return done ? ContentMenuResult.blocked : null;
  }
}

/// El "···" que abre un menú junto a un nombre o al final de una fila de
/// acciones: tres puntos en tinta apagada, con aire para el toque.
class MoreDots extends StatelessWidget {
  const MoreDots({super.key, required this.onTap, this.padding = const EdgeInsets.all(10)});

  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Semantics(
        label: context.l10n.menuMore,
        button: true,
        child: Padding(
          padding: padding,
          child: Text(
            '···',
            style: VText.ui(14, weight: 700, letterSpacing: 1, color: pressed ? c.ink : c.ink3, height: 1),
          ),
        ),
      ),
    );
  }
}

/// Avatar gris de una cuenta bloqueada (sin su foto ni su color).
class BlockedAvatar extends StatelessWidget {
  const BlockedAvatar({super.key, required this.name, this.size = 40, this.ring = false});

  final String name;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    Widget avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: blockedAvatarColor(c), shape: BoxShape.circle),
      child: Text(
        initial,
        style: VText.ui(size * 0.375, weight: 600, height: 1, color: c.inkA(size >= 80 ? 0.5 : 0.6)),
      ),
    );
    if (ring) {
      avatar = Container(
        padding: const EdgeInsets.all(UserAvatar.ringWidth),
        decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
        child: avatar,
      );
    }
    return avatar;
  }
}

/// Una fila plana con texto y, a la derecha, un dato en mono con su flecha
/// ("Mis reportes   2 →").
class MonoArrowRow extends StatelessWidget {
  const MonoArrowRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.strongLine = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  /// La línea de abajo es la de las secciones (14 %), no la suave.
  final bool strongLine;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(bottom: BorderSide(color: strongLine ? c.line : c.lineSoft)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.ui(16, weight: 500)),
            ),
            const SizedBox(width: 12),
            VMono(value.isEmpty ? '→' : '$value →', size: 11, tracking: 0, color: c.ink4, uppercase: false),
          ],
        ),
      ),
    );
  }
}
