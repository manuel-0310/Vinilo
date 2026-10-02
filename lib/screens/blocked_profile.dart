import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'moderation_actions.dart';
import 'profile_header.dart';

/// El perfil de alguien a quien bloqueé: el banner y el avatar en gris, su
/// nombre y su @usuario, y la tarjeta "Bloqueaste a esta cuenta" con
/// "Desbloquear". Recién desbloqueado (`blocked` false) la tarjeta dice "Ya
/// no está bloqueado" y el botón pasa a "Seguir", que además abre el perfil
/// de verdad.
class BlockedProfile extends StatefulWidget {
  const BlockedProfile({
    super.key,
    required this.person,
    required this.blocked,
    required this.onUnblocked,
    required this.onFollowed,
  });

  final PersonInfo person;
  final bool blocked;

  /// Se quitó el bloqueo.
  final VoidCallback onUnblocked;

  /// Se tocó "Seguir" después de desbloquear.
  final VoidCallback onFollowed;

  @override
  State<BlockedProfile> createState() => _BlockedProfileState();
}

class _BlockedProfileState extends State<BlockedProfile> {
  bool _busy = false;

  Future<void> _unblock() async {
    if (_busy) return;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).moderation;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await repo.unblock(me: me.uid, other: widget.person.uid);
      HapticFeedback.selectionClick();
      widget.onUnblocked();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.unblockFailed(describeError(e, l)))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _follow() async {
    if (_busy) return;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).follows;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await repo.setFollowing(me: me, other: widget.person, follow: true);
      HapticFeedback.lightImpact();
      widget.onFollowed();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotSave(describeError(e, l)))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _menu() async {
    final choice = await showProfileMenu(
      context,
      person: widget.person,
      blocked: widget.blocked,
      withShare: false,
    );
    if (choice == ProfileMenuAction.unblock) await _unblock();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final person = widget.person;
    final blocked = widget.blocked;
    final topPad = MediaQuery.paddingOf(context).top;
    final bannerHeight = topPad + profileBannerBelowStatus;
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 30),
      children: [
        SizedBox(
          height: bannerHeight + 96 - 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: bannerHeight,
                child: ColoredBox(color: c.surface),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: topPad + 4,
                child: Row(
                  children: [
                    VIconButton(
                      key: const ValueKey('back'),
                      icon: VIcon.back,
                      style: VIconButtonStyle.filled,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    VIconButton(
                      key: const ValueKey('profile-more'),
                      icon: VIcon.more,
                      style: VIconButtonStyle.filled,
                      tooltip: l.menuMore,
                      onTap: _menu,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: VSpace.page,
                top: bannerHeight - 44,
                child: BlockedAvatar(name: person.name, size: 88, ring: true),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                person.name,
                key: const ValueKey('profile-name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VText.display(50, weight: 800, height: 0.9, tracking: 0),
              ),
              if (person.username != null) ...[
                const SizedBox(height: 6),
                VMono(person.handle, key: const ValueKey('profile-handle'), maxLines: 1),
              ],
              const SizedBox(height: 40),
              Container(
                key: ValueKey(blocked ? 'blocked-card' : 'unblocked-card'),
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: c.line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VMono(blocked ? l.blockedTag : l.unblockedTag, color: c.danger),
                    const SizedBox(height: 8),
                    Text(
                      blocked ? l.blockedTitle : l.unblockedTitle,
                      style: VText.display(28, weight: 700, stretch: 70, height: 1.05, tracking: 0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blocked ? l.blockedBody : l.unblockedBody,
                      style: VText.ui(14, height: 1.45, color: c.inkA(0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              VSecondaryButton(
                key: ValueKey(blocked ? 'profile-unblock' : 'profile-follow-again'),
                label: blocked ? l.unblock : l.followPlain,
                busy: _busy,
                onPressed: blocked ? _unblock : _follow,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
