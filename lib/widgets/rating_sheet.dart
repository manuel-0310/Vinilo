import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/album.dart';
import '../models/rating.dart';
import '../services/services.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import 'album_cover.dart';
import 'rating_dial.dart';

enum RatingSheetResult { saved, deleted }

Future<RatingSheetResult?> showRatingSheet(
  BuildContext context, {
  required Album album,
  RatingEntry? existing,
}) {
  return showModalBottomSheet<RatingSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => RatingSheet(album: album, existing: existing),
  );
}

class RatingSheet extends StatefulWidget {
  const RatingSheet({super.key, required this.album, this.existing});

  final Album album;
  final RatingEntry? existing;

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
    _score = widget.existing?.score;
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
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('¿Borrar tu nota?', style: VText.display(26)),
        content: Text(
          '“${widget.album.name}” saldrá de tu diario y del promedio.',
          style: VText.ui(14, color: VColors.text2, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Borrar',
              style: VText.ui(14, weight: 700, color: VColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    setState(() => _busy = true);
    try {
      await services.ratings.remove(uid: me.uid, albumId: widget.album.id);
      HapticFeedback.lightImpact();
      if (mounted) Navigator.of(context).pop(RatingSheetResult.deleted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final color = score == null ? VColors.text3 : Score.color(score);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: VColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: VColors.line)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VColors.text3.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  AlbumCover(url: widget.album.smallCover, size: 54, radius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(15, weight: 700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.album.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(13, color: VColors.text2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 230),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: score == null
                        ? Text(
                            '–',
                            key: const ValueKey('none'),
                            style: VText.display(110, color: VColors.text3),
                          )
                        : Text(
                            '$score',
                            key: ValueKey(score),
                            style: VText.display(118, color: color, height: 1),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    score == null ? 'Toca o desliza para elegir tu nota' : Score.label(score),
                    key: ValueKey(score),
                    textAlign: TextAlign.center,
                    style: VText.display(
                      24,
                      italic: true,
                      color: score == null ? VColors.text3 : color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              RatingDial(
                value: score,
                onChanged: (v) => setState(() => _score = v),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('note-field'),
                controller: _note,
                maxLength: 180,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: VText.ui(15),
                decoration: InputDecoration(
                  hintText: 'Una línea sobre este disco (opcional)',
                  counterStyle: VText.label(10),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('rating-save'),
                onPressed: score == null || _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VColors.onAccent,
                        ),
                      )
                    : Text(
                        widget.existing == null
                            ? 'Guardar en mi diario'
                            : 'Actualizar mi nota',
                      ),
              ),
              if (widget.existing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextButton(
                    onPressed: _busy ? null : _delete,
                    child: Text(
                      'Borrar nota',
                      style: VText.ui(14, weight: 600, color: VColors.danger),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
