import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import 'album_cover.dart';
import 'line_field.dart';
import 'rating_bars.dart';
import 'same_score_sheet.dart';
import 'sheet.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// `deleted`: la persona pidió borrar su nota; todavía no se ha borrado (lo
/// hace quien abrió la hoja, con "Deshacer"). `queued`: no había conexión y
/// la nota quedó en la cola del teléfono.
enum RatingSheetResult { saved, deleted, queued }

/// Largo máximo del comentario de una nota.
const int ratingNoteMaxLength = 180;

Future<RatingSheetResult?> showRatingSheet(
  BuildContext context, {
  required Album album,
  RatingEntry? existing,
  int? initialScore,
  String? initialNote,
  bool pending = false,
  Color? tone,
}) {
  return showVSheet<RatingSheetResult>(
    context,
    (_) => RatingSheet(
      album: album,
      existing: existing,
      initialScore: initialScore,
      initialNote: initialNote,
      pending: pending,
      tone: tone,
    ),
  );
}

/// Calificar: el disco arriba (portada de 48, título y "Artista · año", ×),
/// el número grande en énfasis con "Tu nota" y el veredicto, las 10 barras
/// (se tocan o se desliza el dedo), el comentario opcional, "Guardar mi
/// nota", "Otros discos calificados con N" (abre la lista de mis discos
/// con esa nota) y, si ya había nota, "Borrar nota". La primera vez no hay barra
/// elegida: el número es "—" y guardar se activa al elegir una.
///
/// Si no hay conexión, la nota queda en la cola del teléfono
/// (`RatingsRepo.queue`) y la hoja muestra "No pudimos guardar tu nota ·
/// Reintentar" (prototipo "Error al guardar"): sin las barras ni el
/// comentario, con el número arriba y "Guardar mi nota" debajo, que también
/// reintenta. Si se cierra así, la nota sube sola cuando vuelve la señal.
class RatingSheet extends StatefulWidget {
  const RatingSheet({
    super.key,
    required this.album,
    this.existing,
    this.initialScore,
    this.initialNote,
    this.pending = false,
    this.tone,
  });

  final Album album;
  final RatingEntry? existing;

  /// Nota preseleccionada; si no, la que ya tenía (o ninguna).
  final int? initialScore;

  /// Comentario de partida; si no, el que ya tenía.
  final String? initialNote;

  /// Hay una versión de esta nota esperando conexión: al guardar con
  /// conexión sale de la cola.
  final bool pending;

  /// El tono de la portada, como en el disco: pinta el número, el
  /// veredicto, las barras, el foco del comentario y "Guardar mi nota".
  /// Sin él, el énfasis.
  final Color? tone;

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int? _score;
  late final TextEditingController _note;
  bool _busy = false;

  /// No se pudo guardar por falta de conexión (la nota está en la cola).
  bool _failed = false;

  /// Mis notas, para "Otros discos calificados con N" (null mientras
  /// cargan o si fallan).
  List<RatingEntry>? _mine;
  bool _mineAsked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mineAsked) return;
    _mineAsked = true;
    final me = CurrentUser.maybeOf(context);
    final services = ServicesScope.maybeOf(context);
    if (me == null || services == null) return;
    services.ratings.fetchUserRatings(me.uid).then((list) {
      if (mounted) setState(() => _mine = list);
    }, onError: (_) {});
  }

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore ?? widget.existing?.score;
    _note = TextEditingController(text: widget.initialNote ?? widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Cuánto se espera a Firestore antes de dar la nota por no guardada (sin
  /// conexión, una transacción reintenta un buen rato antes de fallar).
  static const Duration _saveTimeout = Duration(seconds: 12);

  Future<void> _save() async {
    final score = _score;
    if (score == null || _busy) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    final note = _note.text.trim();
    setState(() => _busy = true);
    try {
      // Sin conexión ni se intenta: directo a la cola.
      if (services.connectivity.offline) {
        throw TimeoutException('offline');
      }
      await services.ratings
          .rate(user: me, album: widget.album, score: score, note: note)
          .timeout(_saveTimeout);
      // Lo que esperaba en la cola ya no hace falta (sin esperar: con
      // conexión sale enseguida).
      if (widget.pending || _failed) {
        unawaited(services.ratings.clearPending(me.uid, widget.album.id).catchError((Object _) {}));
      }
      services.connectivity.reportSuccess();
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(RatingSheetResult.saved);
    } catch (e) {
      if (!mounted) return;
      if (isOfflineError(e)) {
        // Firestore la deja en el teléfono al instante; el Future se cumple
        // cuando sube, así que no se espera.
        unawaited(
          services.ratings
              .queue(uid: me.uid, album: widget.album, score: score, note: note)
              .catchError((Object _) {}),
        );
        services.connectivity.reportFailure();
        HapticFeedback.lightImpact();
        setState(() {
          _busy = false;
          _failed = true;
        });
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSave(describeError(e, context.l10n)))),
      );
    }
  }

  /// Cerrar con la nota en la cola: quien abrió la hoja sabe que quedó
  /// pendiente.
  void _close() {
    Navigator.of(context).maybePop(_failed ? RatingSheetResult.queued : null);
  }

  /// "Borrar nota" no pregunta ni borra aquí: devuelve `deleted` y quien
  /// abrió la hoja muestra "Deshacer" y borra de verdad cuando el aviso se
  /// cierra sin deshacer (así la nota vuelve tal cual y los promedios del
  /// disco solo se mueven una vez).
  void _delete() {
    if (_busy) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(RatingSheetResult.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final score = _score;
    final album = widget.album;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final tone = widget.tone ?? c.accentText;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.sheet,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              // El disco: portada, título, "Artista · año" y cerrar.
              Container(
                padding: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line)),
                ),
                child: Row(
                  children: [
                    AlbumCover(url: album.smallCover, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VText.ui(16, weight: 600),
                          ),
                          Text(
                            album.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VText.ui(13, color: c.ink3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    VIconButton(
                      key: const ValueKey('rating-close'),
                      icon: VIcon.close,
                      iconSize: 16,
                      tooltip: l.cancel,
                      onTap: _close,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // El número grande y, a la derecha, "Tu nota" con el veredicto.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      score == null ? '—' : '$score',
                      key: const ValueKey('rating-number'),
                      maxLines: 1,
                      style: VText.display(
                        150,
                        weight: 800,
                        height: 0.78,
                        tracking: -0.02,
                        color: score == null ? c.inkA(0.28) : tone,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        VMono(l.yourRating),
                        const SizedBox(height: 4),
                        Text(
                          score == null ? '' : Score.label(score, l),
                          key: const ValueKey('rating-verdict'),
                          style: VText.display(28, weight: 700, stretch: 70, height: 1, tracking: 0, color: tone),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_failed) ...[
                const SizedBox(height: 22),
                _SaveFailed(busy: _busy, onRetry: _save),
              ] else ...[
                const SizedBox(height: 22),
                RatingBars(
                  value: score,
                  color: widget.tone,
                  onChanged: (v) => setState(() => _score = v),
                ),
                const SizedBox(height: 8),
                VMono(l.rateSheetHint, size: 10, tracking: 0.06, color: c.ink4),
                const SizedBox(height: 16),
                LineField(
                  fieldKey: const ValueKey('note-field'),
                  controller: _note,
                  hint: l.rateSheetCommentHint,
                  maxLength: ratingNoteMaxLength,
                  fontSize: 15,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  focusColor: widget.tone,
                ),
              ],
              const SizedBox(height: 14),
              if (widget.tone != null)
                VPrimaryButton.tone(
                  key: const ValueKey('rating-save'),
                  label: l.rateSheetSaveMine,
                  color: widget.tone!,
                  busy: _busy,
                  onPressed: score == null ? null : _save,
                )
              else
                VPrimaryButton.accent(
                  key: const ValueKey('rating-save'),
                  label: l.rateSheetSaveMine,
                  busy: _busy,
                  onPressed: score == null ? null : _save,
                ),
              if (score != null && !_failed) ...[
                const SizedBox(height: 8),
                SameScoreButton(
                  score: score,
                  mine: _mine,
                  except: album.id,
                  tone: widget.tone,
                ),
              ],
              if (widget.existing != null && !_failed) ...[
                const SizedBox(height: 4),
                Pressable(
                  key: const ValueKey('rating-delete'),
                  onTap: _busy ? null : _delete,
                  builder: (context, pressed) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l.rateSheetDelete,
                      textAlign: TextAlign.center,
                      style: VText.ui(14, weight: 500, color: pressed ? c.ink : c.inactive),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "No pudimos guardar tu nota" (prototipo "Error al guardar"): borde de
/// peligro, el título en peligro, "No perdiste nada, la guardamos en tu
/// teléfono." y "Reintentar" a la derecha.
class _SaveFailed extends StatelessWidget {
  const _SaveFailed({required this.busy, required this.onRetry});

  final bool busy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Pressable(
      key: const ValueKey('rating-failed'),
      onTap: busy ? null : onRetry,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: c.danger)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.rateSaveFailedTitle, style: VText.ui(15, weight: 600, color: c.danger)),
                  const SizedBox(height: 3),
                  Text(l.rateSaveFailedBody, style: VText.ui(13, color: c.ink2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              const VSpinner(size: 12)
            else
              Opacity(
                opacity: pressed ? 0.6 : 1,
                child: VMono(l.retry, key: const ValueKey('rating-retry'), tracking: 0.06, color: c.ink),
              ),
          ],
        ),
      ),
    );
  }
}
