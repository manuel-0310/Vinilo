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
import '../widgets/line_field.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'moderation_actions.dart';
import 'privacy_screen.dart';

/// "¿Qué está pasando?": se elige un motivo (uno solo), se agregan detalles
/// si se quiere y se envía. Reportar un comentario lo oculta de inmediato
/// para quien reporta. Al enviar pasa a `ReportSentScreen`.
class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.type,
    required this.targetId,
    required this.target,
    this.ratingId,
    this.excerpt = '',
  });

  final ReportTarget type;

  /// El uid, el id de la nota o el id de la respuesta.
  final String targetId;

  /// La persona reportada o la autora del comentario.
  final PersonInfo target;
  final String? ratingId;

  /// Lo que dice el comentario (se guarda con el reporte).
  final String excerpt;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).moderation;
    final l = context.l10n;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final report = await repo.report(
        reporter: me.uid,
        type: widget.type,
        targetId: widget.targetId,
        target: widget.target,
        ratingId: widget.ratingId,
        reason: reason,
        details: _details.text,
        excerpt: widget.excerpt,
      );
      HapticFeedback.mediumImpact();
      navigator.pushReplacement(
        CupertinoPageRoute(builder: (_) => ReportSentScreen(report: report)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l.reportFailed(describeError(e, l)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final handle = handleOf(widget.target);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomPad = keyboard ? 14.0 : math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: VIconButton(
                  key: const ValueKey('report-close'),
                  icon: VIcon.close,
                  iconSize: 16,
                  tooltip: l.cancel,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VMono(
                      widget.type.isContent ? l.reportOverlineComment(handle) : l.menuReportUser(handle),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.reportTitle,
                      key: const ValueKey('report-title'),
                      style: VText.display(46, weight: 800, height: 0.9, tracking: 0),
                    ),
                    const SizedBox(height: 8),
                    Text(l.reportAnonymous(handle), style: VText.ui(14, height: 1.45, color: c.ink2)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                      child: Column(
                        children: [
                          for (final reason in ReportReason.values)
                            _ReasonRow(
                              key: ValueKey('report-reason-${reason.key}'),
                              reason: reason,
                              selected: reason == _reason,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _reason = reason);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    LineField(
                      fieldKey: const ValueKey('report-details'),
                      controller: _details,
                      hint: l.reportDetailsHint,
                      fontSize: 15,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [LengthLimitingTextInputFormatter(reportDetailsMaxLength)],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, bottomPad),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: VPrimaryButton.accent(
                key: const ValueKey('report-send'),
                label: l.reportSend,
                busy: _busy,
                mutedWhenDisabled: true,
                onPressed: _reason == null ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un motivo: su nombre, una explicación y el círculo de elegir (con un aro
/// de 6 en énfasis cuando está elegido).
class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    super.key,
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
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
                  Text(reason.title(l), style: VText.ui(16, weight: 500)),
                  const SizedBox(height: 2),
                  Text(reason.hint(l), style: VText.ui(12.5, color: c.ink4)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.accent : c.inkA(0.4),
                  width: selected ? 6 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Gracias por avisarnos": el número del reporte y su motivo, qué va a
/// pasar, el interruptor para bloquear también a la persona, "Listo" y el
/// enlace a "Mis reportes".
class ReportSentScreen extends StatefulWidget {
  const ReportSentScreen({super.key, required this.report});

  final Report report;

  @override
  State<ReportSentScreen> createState() => _ReportSentScreenState();
}

class _ReportSentScreenState extends State<ReportSentScreen> {
  bool _alsoBlock = false;
  bool _busy = false;

  /// Bloquea si el interruptor quedó encendido. Devuelve false si falló.
  Future<bool> _applyBlock() async {
    if (!_alsoBlock) return true;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).moderation;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await repo.block(me: me, other: widget.report.target);
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.blockFailed(describeError(e, l)))));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _done() async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    if (await _applyBlock()) navigator.pop();
  }

  Future<void> _seeReports() async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    if (!await _applyBlock()) return;
    navigator.pushReplacement(CupertinoPageRoute(builder: (_) => const MyReportsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final report = widget.report;
    final handle = handleOf(report.target);
    final alreadyBlocked = Moderation.of(context).isBlocked(report.target.uid);
    final bottomPad = math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                      child: Row(
                        children: [
                          Expanded(
                            child: VMono(
                              l.reportNumber('${report.number}'),
                              key: const ValueKey('report-number'),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          VMono(report.reason.short(l), maxLines: 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      l.reportSentTitle,
                      key: const ValueKey('report-sent-title'),
                      style: VText.display(64, weight: 800, height: 0.86, tracking: 0),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      report.targetType.isContent ? l.reportSentBodyComment : l.reportSentBodyUser,
                      style: VText.ui(15, height: 1.45, color: c.ink2),
                    ),
                    if (!alreadyBlocked) ...[
                      const SizedBox(height: 28),
                      Container(
                        // Los 16 de arriba y abajo del prototipo, menos los 8
                        // que el interruptor trae para el toque.
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.symmetric(horizontal: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.reportAlsoBlock(handle), style: VText.ui(16, weight: 600)),
                                  const SizedBox(height: 3),
                                  Text(l.reportAlsoBlockHint, style: VText.ui(12.5, color: c.inkA(0.55))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            VSwitch(
                              key: const ValueKey('report-also-block'),
                              value: _alsoBlock,
                              onChanged: _busy ? null : (v) => setState(() => _alsoBlock = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Spacer(),
                    VPrimaryButton(
                      key: const ValueKey('report-done'),
                      label: l.done,
                      busy: _busy,
                      onPressed: _done,
                    ),
                    Pressable(
                      key: const ValueKey('report-see-mine'),
                      onTap: _seeReports,
                      // El enlace queda a 38 del borde; los 14 de abajo son
                      // parte del toque.
                      builder: (context, pressed) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: VMono(
                          l.reportSeeMine,
                          tracking: 0.06,
                          align: TextAlign.center,
                          color: pressed ? c.ink : c.ink4,
                        ),
                      ),
                    ),
                    SizedBox(height: math.max(0, bottomPad - 14)),
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
