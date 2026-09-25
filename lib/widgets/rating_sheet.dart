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
import 'sheet.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// `deleted`: la persona pidió borrar su nota; todavía no se ha borrado (lo
/// hace quien abrió la hoja, con "Deshacer").
enum RatingSheetResult { saved, deleted }

/// Largo máximo del comentario de una nota.
const int ratingNoteMaxLength = 180;

Future<RatingSheetResult?> showRatingSheet(
  BuildContext context, {
  required Album album,
  RatingEntry? existing,
  int? initialScore,
}) {
  return showVSheet<RatingSheetResult>(
    context,
    (_) => RatingSheet(
      album: album,
      existing: existing,
      initialScore: initialScore,
    ),
  );
}

/// Calificar: el disco arriba (portada de 48, título y "Artista · año", ×),
/// el número grande en énfasis con "Tu nota" y el veredicto, las 10 barras
/// (se tocan o se desliza el dedo), el comentario opcional, "Guardar mi
/// nota" y, si ya había nota, "Borrar nota". La primera vez no hay barra
/// elegida: el número es "—" y guardar se activa al elegir una.
class RatingSheet extends StatefulWidget {
  const RatingSheet({
    super.key,
    required this.album,
    this.existing,
    this.initialScore,
  });

  final Album album;
  final RatingEntry? existing;

  /// Nota preseleccionada; si no, la que ya tenía (o ninguna).
  final int? initialScore;

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int? _score;
  late final TextEditingController _note;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore ?? widget.existing?.score;
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final score = _score;
    if (score == null || _busy) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    setState(() => _busy = true);
    try {
      await services.ratings.rate(
        user: me,
        album: widget.album,
        score: score,
        note: _note.text.trim(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(RatingSheetResult.saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSave(describeError(e, context.l10n)))),
      );
    }
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
                      onTap: () => Navigator.of(context).maybePop(),
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
                        color: score == null ? c.inkA(0.28) : c.accent,
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
                          style: VText.display(28, weight: 700, stretch: 70, height: 1, tracking: 0, color: c.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              RatingBars(
                value: score,
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
              ),
              const SizedBox(height: 14),
              VPrimaryButton.accent(
                key: const ValueKey('rating-save'),
                label: l.rateSheetSaveMine,
                busy: _busy,
                onPressed: score == null ? null : _save,
              ),
              if (widget.existing != null) ...[
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
