import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/reply.dart';
import '../screens/routes.dart';
import '../theme/vinilo_theme.dart';

/// Texto con las menciones (@usuario) en el color de énfasis; al tocar una
/// se abre el perfil de esa persona.
class MentionText extends StatefulWidget {
  const MentionText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  /// Un reconocedor por mención; se guardan para liberarlos.
  TapGestureRecognizer _tapFor(String handle) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => openUserByHandle(context, handle);
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    _clearRecognizers();
    final spans = <InlineSpan>[
      for (final piece in splitMentions(widget.text))
        if (piece.handle == null)
          TextSpan(text: piece.text)
        else
          TextSpan(
            text: piece.text,
            // Manrope es variable: el grosor va en `fontVariations`.
            style: TextStyle(
              color: c.accent,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation('wght', 700)],
            ),
            recognizer: _tapFor(piece.handle!),
          ),
    ];
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
