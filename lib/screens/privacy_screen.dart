import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/moderation.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/format.dart';
import '../util/support.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'moderation_actions.dart';
import 'routes.dart';

Future<void> openPrivacy(BuildContext context) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => const PrivacyScreen()),
  );
}

/// Ajustes · Privacidad y seguridad: el filtro de comentarios ofensivos,
/// "Mis reportes", "Cuentas silenciadas", la lista de cuentas bloqueadas
/// (cada una con "Desbloquear") y el correo de soporte.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _unblock(BuildContext context, BlockEdge edge) async {
    final repo = ServicesScope.of(context).moderation;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();
    try {
      await repo.unblock(me: edge.blocker, other: edge.blocked);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.unblockFailed(describeError(e, l)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    // Al borrar la cuenta la pantalla puede quedarse un instante sin perfil.
    final me = CurrentUser.maybeOf(context);
    if (me == null) return const Scaffold();
    final services = ServicesScope.of(context);
    final moderation = Moderation.of(context);
    final blocked = moderation.blocked.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad + 30),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: VIconButton(
                  key: const ValueKey('back'),
                  icon: VIcon.back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.privacyTitle,
                    key: const ValueKey('privacy-title'),
                    style: VText.display(46, weight: 800, height: 0.9, tracking: 0),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Los 14 del prototipo, menos los 8 que el interruptor
                        // trae para el toque.
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: c.lineSoft)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.privacyFilter, style: VText.ui(16, weight: 500)),
                                    const SizedBox(height: 2),
                                    Text(
                                      l.privacyFilterHint,
                                      style: VText.ui(12.5, color: c.inkA(0.55)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              VSwitch(
                                key: const ValueKey('privacy-filter'),
                                value: me.filterOffensive,
                                onChanged: (v) => services.users.setFilterOffensive(me.uid, v),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<List<Report>>(
                          stream: services.moderation.myReports(me.uid),
                          builder: (context, snap) => MonoArrowRow(
                            key: const ValueKey('privacy-reports'),
                            label: l.privacyMyReports,
                            value: snap.hasData ? '${snap.data!.length}' : '',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => const MyReportsScreen()),
                            ),
                          ),
                        ),
                        MonoArrowRow(
                          key: const ValueKey('privacy-muted'),
                          label: l.privacyMuted,
                          value: '${moderation.muted.length}',
                          strongLine: true,
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => const MutedAccountsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 22, bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: VMono(l.privacyBlocked, maxLines: 1)),
                        VMono('${blocked.length}', key: const ValueKey('privacy-blocked-count')),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: blocked.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              l.privacyNoBlocked,
                              key: const ValueKey('privacy-no-blocked'),
                              style: VText.ui(14, color: c.ink4),
                            ),
                          )
                        : Column(
                            children: [
                              for (final (i, edge) in blocked.indexed)
                                _AccountRow(
                                  key: ValueKey('blocked-$i'),
                                  name: edge.blockedInfo.name,
                                  caption: l.privacyBlockedAgo(relativeAgo(edge.createdAt, l)),
                                  action: l.unblock,
                                  actionKey: ValueKey('unblock-$i'),
                                  onAction: () => _unblock(context, edge),
                                  onTap: () => openUser(context, edge.blocked),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    key: const ValueKey('privacy-support'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: supportEmail));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(l.emailCopied), duration: const Duration(seconds: 2)),
                        );
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l.privacySupportLead),
                          TextSpan(text: supportEmail, style: TextStyle(color: c.ink)),
                        ],
                      ),
                      style: VText.ui(12.5, height: 1.45, color: c.ink4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una cuenta bloqueada o silenciada: avatar de 40 (gris si está
/// bloqueada), el nombre, una línea mono ("Bloqueado hace 2 días") y un
/// botón con borde a la derecha.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    super.key,
    required this.name,
    required this.caption,
    required this.action,
    required this.onAction,
    this.onTap,
    this.actionKey,
    this.avatar,
  });

  final String name;
  final String caption;
  final String action;
  final VoidCallback onAction;
  final VoidCallback? onTap;
  final Key? actionKey;

  /// Otro avatar (el de verdad, en las silenciadas); por defecto, el gris.
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Row(
                children: [
                  avatar ?? BlockedAvatar(name: name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(15, weight: 600),
                        ),
                        const SizedBox(height: 3),
                        VMono(caption, size: 10, tracking: 0.06, color: c.ink4, maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Pressable(
            key: actionKey,
            onTap: onAction,
            builder: (context, pressed) => Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: pressed ? c.ink : c.lineStrong),
              ),
              child: Text(action, maxLines: 1, style: VText.ui(13, weight: 500)),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cuentas silenciadas": a quién silencié, con "Dejar de silenciar".
class MutedAccountsScreen extends StatelessWidget {
  const MutedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final me = CurrentUser.maybeOf(context);
    if (me == null) return const Scaffold();
    final repo = ServicesScope.of(context).moderation;
    final muted = Moderation.of(context).muted.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 30),
          children: [
            VPageHeader(
              title: l.privacyMuted,
              titleSize: 46,
              subtitle: l.countAccounts(muted.length),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
              child: Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                child: muted.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l.privacyNoMuted, style: VText.ui(14, color: c.ink4)),
                      )
                    : Column(
                        children: [
                          for (final (i, m) in muted.indexed)
                            _AccountRow(
                              key: ValueKey('muted-$i'),
                              name: m.info.name,
                              caption: l.privacyMutedAgo(relativeAgo(m.createdAt, l)),
                              action: l.menuUnmute,
                              actionKey: ValueKey('unmute-$i'),
                              avatar: UserAvatar(
                                name: m.info.name,
                                color: Color(m.info.colorValue),
                                url: m.info.avatarUrl,
                                size: 40,
                                initialSize: 15,
                              ),
                              onAction: () {
                                HapticFeedback.selectionClick();
                                repo.unmute(me: me.uid, other: m.info.uid);
                              },
                              onTap: () => openUser(context, m.info.uid),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Mis reportes": lo que reporté, del más reciente al más antiguo, con su
/// número, el motivo y en qué va.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  static String statusLabel(Report report, AppLocalizations l) {
    if (report.status == ReportStatus.open) return l.reportStatusOpen;
    return report.outcome == 'removed' ? l.reportStatusRemoved : l.reportStatusDismissed;
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final me = CurrentUser.maybeOf(context);
    if (me == null) return const Scaffold();
    final moderationText = Moderation.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Report>>(
          stream: ServicesScope.of(context).moderation.myReports(me.uid),
          builder: (context, snap) {
            final reports = snap.data;
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 30),
              children: [
                VPageHeader(
                  title: l.privacyMyReports,
                  titleSize: 46,
                  subtitle: reports == null ? l.loading : l.countReports(reports.length),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                  child: Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: snap.hasError
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              describeError(snap.error, l),
                              style: VText.ui(14, color: c.danger),
                            ),
                          )
                        : reports == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: VSkeleton(height: 44),
                              )
                            : reports.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Text(l.privacyNoReports, style: VText.ui(14, color: c.ink4)),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (final (i, r) in reports.indexed)
                                        Container(
                                          key: ValueKey('my-report-$i'),
                                          padding: const EdgeInsets.symmetric(vertical: 13),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: c.lineSoft)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: VMono(
                                                      '${l.reportNumber('${r.number}')} · ${r.reason.short(l)}',
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  VMono(
                                                    relativeAgo(r.createdAt, l),
                                                    size: 10,
                                                    tracking: 0.06,
                                                    color: c.ink4,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                r.targetType.isContent
                                                    ? l.reportTargetComment(handleOf(r.target))
                                                    : l.reportTargetUser(handleOf(r.target)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: VText.ui(16, weight: 500),
                                              ),
                                              if (r.excerpt.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  '“${moderationText.text(r.excerpt)}”',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: VText.ui(13, height: 1.4, color: c.ink2),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              VMono(
                                                statusLabel(r, l),
                                                size: 10,
                                                tracking: 0.06,
                                                color: r.status == ReportStatus.open ? c.accentText : c.ink4,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
