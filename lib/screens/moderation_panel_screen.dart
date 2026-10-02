import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/moderation.dart';
import '../models/support.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/format.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';
import 'moderation_actions.dart';
import 'routes.dart';
import 'search_all_screen.dart';

Future<void> openModerationPanel(BuildContext context) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => const ModerationPanelScreen()),
  );
}

/// El panel de quien modera (tiene su documento en `admins/{uid}`; la
/// entrada "Moderación" de Configuración solo se le ve a esa persona). Sin
/// diseño en los prototipos: usa los bloques de "Mis reportes".
///
/// - Reportes: los abiertos, del más reciente al más antiguo. Un comentario
///   se puede "Retirar" (la nota se queda sin texto; la respuesta se borra)
///   y cualquiera se puede cerrar "Sin cambios"; "Ver" abre el hilo o el
///   perfil.
/// - Problemas: lo que se mandó desde "Se rayó el disco".
/// - Discos pedidos: "Pídenos que lo agreguemos", agrupados por lo que se
///   buscó; tocar uno lo busca.
class ModerationPanelScreen extends StatefulWidget {
  const ModerationPanelScreen({super.key});

  @override
  State<ModerationPanelScreen> createState() => _ModerationPanelScreenState();
}

class _ModerationPanelScreenState extends State<ModerationPanelScreen> {
  int _tab = 0;
  Stream<List<Report>>? _reports;
  Stream<List<ProblemReport>>? _problems;
  Stream<List<AlbumRequest>>? _requests;

  /// Los reportes que se están cerrando ahora (botones ocupados).
  final Set<String> _busy = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reports != null) return;
    final services = ServicesScope.of(context);
    _reports = services.moderation.openReports();
    _problems = services.support.problems();
    _requests = services.support.requests();
  }

  Future<void> _resolve(Report report, {required bool remove}) async {
    final l = context.l10n;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).moderation;
    final messenger = ScaffoldMessenger.of(context);
    if (remove) {
      final ok = await showConfirmSheet(
        context,
        title: l.moderationRemoveTitle,
        message: l.moderationRemoveBody,
        confirmLabel: l.moderationRemove,
        danger: true,
        confirmKey: const ValueKey('moderation-remove-confirm'),
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy.add(report.id));
    try {
      if (remove) {
        await repo.removeContent(report, by: me.uid);
      } else {
        await repo.resolve(report, outcome: 'dismissed', by: me.uid);
      }
      HapticFeedback.lightImpact();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(remove ? l.moderationRemoved : l.moderationDismissed)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.moderationFailed(describeError(e, l)))));
    } finally {
      if (mounted) setState(() => _busy.remove(report.id));
    }
  }

  void _view(Report report) {
    final ratingId = report.ratingId ??
        (report.targetType == ReportTarget.rating ? report.targetId : null);
    if (report.targetType.isContent && ratingId != null && ratingId.isNotEmpty) {
      openThread(context, ratingId: ratingId);
    } else {
      openUser(context, report.target.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Report>>(
          stream: _reports,
          builder: (context, reportsSnap) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: VPageHeader(
                  title: l.moderationTitle,
                  titleSize: 46,
                  subtitle: reportsSnap.hasData ? l.moderationOpen(reportsSnap.data!.length) : l.loading,
                  subtitleKey: const ValueKey('moderation-subtitle'),
                ),
              ),
              SliverToBoxAdapter(
                child: VTabs(
                  labels: [l.moderationTabReports, l.moderationTabProblems, l.moderationTabRequests],
                  keys: const ['moderation-tab-reports', 'moderation-tab-problems', 'moderation-tab-requests'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              switch (_tab) {
                0 => _reportsList(reportsSnap),
                1 => _problemsList(),
                _ => _requestsList(),
              },
              SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(String text, {bool error = false}) {
    final c = VColors.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 0),
        child: Text(text, style: VText.ui(14, color: error ? c.danger : c.ink4)),
      ),
    );
  }

  Widget _loadingRows() => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
          child: Column(
            children: [
              VSkeleton(height: 44),
              SizedBox(height: 12),
              VSkeleton(height: 44),
            ],
          ),
        ),
      );

  Widget _reportsList(AsyncSnapshot<List<Report>> snap) {
    final l = context.l10n;
    if (snap.hasError) return _message(describeError(snap.error, l), error: true);
    final reports = snap.data;
    if (reports == null) return _loadingRows();
    if (reports.isEmpty) return _message(l.moderationNoReports);
    return SliverList.builder(
      itemCount: reports.length,
      itemBuilder: (context, i) => _ReportRow(
        key: ValueKey('moderation-report-$i'),
        index: i,
        report: reports[i],
        busy: _busy.contains(reports[i].id),
        onView: () => _view(reports[i]),
        onDismiss: () => _resolve(reports[i], remove: false),
        onRemove: reports[i].targetType.isContent ? () => _resolve(reports[i], remove: true) : null,
      ),
    );
  }

  Widget _problemsList() {
    final l = context.l10n;
    final c = VColors.of(context);
    return StreamBuilder<List<ProblemReport>>(
      stream: _problems,
      builder: (context, snap) {
        if (snap.hasError) return _message(describeError(snap.error, l), error: true);
        final problems = snap.data;
        if (problems == null) return _loadingRows();
        if (problems.isEmpty) return _message(l.moderationNoProblems);
        return SliverList.builder(
          itemCount: problems.length,
          itemBuilder: (context, i) {
            final p = problems[i];
            return Container(
              key: ValueKey('moderation-problem-$i'),
              margin: const EdgeInsets.symmetric(horizontal: VSpace.page),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: VMono(p.code, maxLines: 1, color: c.ink)),
                      const SizedBox(width: 12),
                      VMono(relativeAgo(p.createdAt, l), size: 10, tracking: 0.06, color: c.ink4),
                    ],
                  ),
                  if (p.detail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(p.detail, maxLines: 4, overflow: TextOverflow.ellipsis, style: VText.ui(13, height: 1.4, color: c.ink2)),
                  ],
                  const SizedBox(height: 6),
                  VMono(l.moderationReportedBy(p.uid), size: 10, tracking: 0.06, color: c.ink4, uppercase: false),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _requestsList() {
    final l = context.l10n;
    final c = VColors.of(context);
    return StreamBuilder<List<AlbumRequest>>(
      stream: _requests,
      builder: (context, snap) {
        if (snap.hasError) return _message(describeError(snap.error, l), error: true);
        final requests = snap.data;
        if (requests == null) return _loadingRows();
        final groups = groupRequests(requests);
        if (groups.isEmpty) return _message(l.moderationNoRequests);
        return SliverList.builder(
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final g = groups[i];
            return Pressable(
              key: ValueKey('moderation-request-$i'),
              onTap: () => openSearchAll(context, query: g.query, kind: SearchAllKind.albums),
              builder: (context, pressed) => Container(
                margin: const EdgeInsets.symmetric(horizontal: VSpace.page),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: pressed ? c.inkA(0.04) : null,
                  border: Border(bottom: BorderSide(color: c.lineSoft)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.query, maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.ui(16, weight: 500)),
                          const SizedBox(height: 4),
                          VMono(
                            '${l.moderationRequestCount(g.count)} · ${relativeAgo(g.last, l)}',
                            size: 10,
                            tracking: 0.06,
                            color: c.ink4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('→', style: VText.ui(16, color: c.ink4)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Un reporte abierto: "Reporte Nº 4821 · Acoso" con su fecha, a quién
/// (comentario o cuenta), lo que decía, los detalles de quien reportó y las
/// acciones: "Ver", "Sin cambios" y, si es un comentario, "Retirar".
class _ReportRow extends StatelessWidget {
  const _ReportRow({
    super.key,
    required this.index,
    required this.report,
    required this.busy,
    required this.onView,
    required this.onDismiss,
    required this.onRemove,
  });

  final int index;
  final Report report;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onDismiss;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final r = report;
    Widget action(String label, String key, VoidCallback? onTap, {Color? color}) => Pressable(
          key: ValueKey('$key-$index'),
          onTap: busy ? null : onTap,
          builder: (context, pressed) => Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 18),
            child: VMono(label, tracking: 0.06, color: pressed ? c.ink : (color ?? c.ink3)),
          ),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VSpace.page),
      padding: const EdgeInsets.only(top: 13, bottom: 5),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: VMono('${l.reportNumber('${r.number}')} · ${r.reason.short(l)}', maxLines: 1),
              ),
              const SizedBox(width: 12),
              VMono(relativeAgo(r.createdAt, l), size: 10, tracking: 0.06, color: c.ink4),
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
          // Lo que decía, sin pasar por el filtro de palabras: quien modera
          // tiene que verlo tal cual.
          if (r.excerpt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '“${r.excerpt}”',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: VText.ui(13, height: 1.4, color: c.ink2),
            ),
          ],
          if (r.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.details, maxLines: 4, overflow: TextOverflow.ellipsis, style: VText.ui(13, height: 1.4, color: c.ink3)),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              action(l.moderationView, 'moderation-view', onView),
              action(l.moderationDismiss, 'moderation-dismiss', onDismiss),
              if (onRemove != null) action(l.moderationRemove, 'moderation-remove', onRemove, color: c.danger),
              const Spacer(),
              if (busy) const VSpinner(size: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// La fila "Moderación →" de Configuración: solo aparece si quien usa la
/// app tiene su documento en `admins/{uid}`.
class ModerationEntry extends StatelessWidget {
  const ModerationEntry({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return StreamBuilder<bool>(
      stream: ServicesScope.of(context).moderation.isAdmin(uid),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: VSpace.page),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineSoft))),
          child: Pressable(
            key: const ValueKey('moderation-open'),
            onTap: () => openModerationPanel(context),
            builder: (context, pressed) => Container(
              color: pressed ? c.inkA(0.04) : null,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Text(l.settingsModeration, style: VText.ui(16, weight: 500))),
                  Text('→', style: VText.ui(16, weight: 500, color: c.ink4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
