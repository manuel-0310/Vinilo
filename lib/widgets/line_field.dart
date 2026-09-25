import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vinilo_theme.dart';
import 'v_sections.dart';

/// Campo del rediseño: sin caja, una etiqueta mono arriba, el texto y una
/// línea debajo. Con foco, la línea es de 2 px en énfasis y la etiqueta
/// también se pinta de énfasis. El cursor es una barra de 2 px en énfasis.
/// Con `maxLength` muestra el contador ("13/60") a la derecha, debajo.
class LineField extends StatefulWidget {
  const LineField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.maxLength,
    this.prefix,
    this.status,
    this.trailing,
    this.leading,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.fontSize = 17,
    this.fontWeight = 400,
    this.minLines,
    this.maxLines = 1,
    this.fieldKey,
    this.errorKey,
    this.enabled = true,
    this.padding = const EdgeInsets.fromLTRB(0, 8, 0, 10),
  });

  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final int? maxLength;

  /// Texto fijo antes del campo, apagado ("@").
  final String? prefix;

  /// Algo a la derecha de la etiqueta ("✓ Disponible").
  final Widget? status;

  /// Algo a la derecha del texto ("Mostrar", la × de borrar).
  final Widget? trailing;

  /// Algo a la izquierda del texto (la lupa del buscador), a 12.
  final Widget? leading;

  /// Mensaje de error debajo de la línea.
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double fontSize;
  final int fontWeight;
  final int? minLines;
  final int? maxLines;

  /// Llave del `TextField` de dentro (el driver de pruebas escribe ahí).
  final Key? fieldKey;

  /// Llave del texto de error.
  final Key? errorKey;
  final bool enabled;

  /// Relleno alrededor del texto, sin contar la línea.
  final EdgeInsets padding;

  @override
  State<LineField> createState() => _LineFieldState();
}

class _LineFieldState extends State<LineField> {
  FocusNode? _ownFocus;
  TextEditingController? _ownController;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    _controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(LineField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_refresh);
      _focus.addListener(_refresh);
    }
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_refresh);
      _controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _controller.removeListener(_refresh);
    _ownFocus?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final focused = _focus.hasFocus;
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final lineColor = hasError ? c.danger : (focused ? c.accent : c.lineStrong);
    final lineWidth = focused || hasError ? 2.0 : 1.0;
    final textStyle = VText.ui(widget.fontSize, weight: widget.fontWeight, color: c.ink);
    final maxLength = widget.maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.status != null)
          Row(
            children: [
              if (widget.label != null)
                Expanded(
                  child: VMono(
                    widget.label!,
                    size: 10,
                    color: focused ? c.accent : c.ink3,
                  ),
                )
              else
                const Spacer(),
              ?widget.status,
            ],
          ),
        Container(
          // La altura no cambia con el foco: la línea de 2 px se come un
          // píxel del relleno.
          padding: widget.padding.copyWith(
            bottom: widget.padding.bottom + (2 - lineWidth),
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: lineColor, width: lineWidth)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              if (widget.prefix != null)
                Text(widget.prefix!, style: textStyle.copyWith(color: c.placeholder)),
              Expanded(
                child: TextField(
                  key: widget.fieldKey,
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  obscureText: widget.obscure,
                  obscuringCharacter: '•',
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  autofocus: widget.autofocus,
                  autocorrect: widget.autocorrect,
                  enableSuggestions: widget.enableSuggestions,
                  textCapitalization: widget.textCapitalization,
                  inputFormatters: [
                    ...?widget.inputFormatters,
                    if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
                  ],
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  minLines: widget.minLines,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  style: widget.obscure
                      ? textStyle.copyWith(letterSpacing: 0.2 * widget.fontSize, color: c.inkA(0.8))
                      : textStyle,
                  cursorColor: c.accent,
                  cursorWidth: 2,
                  cursorHeight: widget.fontSize + 1,
                  cursorRadius: Radius.zero,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hint,
                    hintStyle: textStyle.copyWith(color: c.placeholder, letterSpacing: 0),
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.error!,
              key: widget.errorKey,
              style: VText.ui(12.5, color: c.danger, height: 1.35),
            ),
          )
        else if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: VMono(
              '${_controller.text.characters.length}/$maxLength',
              size: 10,
              color: c.ink4,
              align: TextAlign.right,
            ),
          ),
      ],
    );
  }
}
