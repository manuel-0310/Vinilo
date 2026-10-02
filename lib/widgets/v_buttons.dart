import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import 'v_icons.dart';

/// Recuerda si el dedo está encima, para imitar el hover del prototipo en
/// una pantalla táctil.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.builder, this.onLongPress});

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: widget.builder(context, _pressed && enabled),
    );
  }
}

/// Botón primario: 56 de alto, texto a la izquierda y "→" a la derecha.
/// Fondo de tinta (`VPrimaryButton`), de énfasis (`.accent`) o de otro
/// color, como el tono de la portada (`.tone`). Al presionarlo cambia de
/// color como el hover del prototipo: la tinta pasa a énfasis y lo demás,
/// a tinta.
class VPrimaryButton extends StatelessWidget {
  const VPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing = '→',
    this.leading,
    this.height = 56,
    this.fontSize = 16,
    this.busy = false,
    this.center = false,
    this.mutedWhenDisabled = false,
    this.trailingIcon,
  })  : _kind = _PrimaryKind.ink,
        color = null;

  const VPrimaryButton.accent({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing = '→',
    this.leading,
    this.height = 56,
    this.fontSize = 16,
    this.busy = false,
    this.center = false,
    this.mutedWhenDisabled = false,
    this.trailingIcon,
  })  : _kind = _PrimaryKind.accent,
        color = null;

  /// Con el color que se le pase (el tono de la portada en el disco).
  const VPrimaryButton.tone({
    super.key,
    required this.label,
    required this.onPressed,
    required Color this.color,
    this.trailing = '→',
    this.leading,
    this.height = 56,
    this.fontSize = 16,
    this.busy = false,
    this.center = false,
    this.mutedWhenDisabled = false,
    this.trailingIcon,
  }) : _kind = _PrimaryKind.tone;

  final String label;
  final VoidCallback? onPressed;

  /// Lo que va a la derecha ("→", "1–10 →"); null para nada.
  final String? trailing;

  /// Algo antes del texto (el check de "Siguiendo").
  final Widget? leading;
  final double height;
  final double fontSize;
  final bool busy;

  /// Texto centrado y sin flecha ("+ Seguir").
  final bool center;

  /// Apagado (`onPressed` null) se ve como un bloque de tinta al 12 % con
  /// el texto al 40 %, en vez de su color atenuado: "Continuar" del
  /// onboarding y "Enviar reporte" hasta que se puede seguir.
  final bool mutedWhenDisabled;

  /// Un ícono a la derecha en lugar del texto de `trailing` (el ↻ de
  /// "Intentar de nuevo").
  final VIcon? trailingIcon;
  final Color? color;
  final _PrimaryKind _kind;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final enabled = onPressed != null && !busy;
    return Pressable(
      onTap: enabled ? onPressed : null,
      builder: (context, pressed) {
        final background = switch (_kind) {
          _PrimaryKind.ink => pressed ? c.accent : c.ink,
          _PrimaryKind.accent => pressed ? c.ink : c.accent,
          _PrimaryKind.tone => pressed ? c.ink : color!,
        };
        final muted = mutedWhenDisabled && onPressed == null;
        final foreground = muted
            ? c.inkA(0.4)
            : (_kind == _PrimaryKind.ink ? c.bg : c.onAccent);
        final text = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VText.ui(fontSize, weight: 600, color: foreground),
        );
        final Widget content;
        if (center) {
          content = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Flexible(child: text),
              if (busy) ...[const SizedBox(width: 10), VSpinner(color: foreground)],
            ],
          );
        } else {
          content = Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(child: text),
              if (busy)
                VSpinner(color: foreground)
              else if (trailingIcon != null)
                VIconView(trailingIcon!, size: 18, color: foreground)
              else if (trailing != null)
                Text(trailing!, style: VText.ui(fontSize, weight: 600, color: foreground)),
            ],
          );
        }
        return Opacity(
          opacity: onPressed == null && !muted ? 0.4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: height,
            color: muted ? c.inkA(0.12) : background,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: content,
          ),
        );
      },
    );
  }
}

enum _PrimaryKind { ink, accent, tone }

/// Botón secundario: borde de 1 px, texto de tinta y "→" apagada (o el
/// texto centrado). Al presionarlo el borde pasa a tinta.
class VSecondaryButton extends StatelessWidget {
  const VSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing = '→',
    this.leading,
    this.height = 52,
    this.fontSize = 16,
    this.weight = 500,
    this.center = false,
    this.color,
    this.borderColor,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? trailing;
  final Widget? leading;
  final double height;
  final double fontSize;
  final int weight;
  final bool center;

  /// Color del texto (por defecto, tinta).
  final Color? color;

  /// Color del borde (por defecto, `lineStrong`; "Siguiendo" va en énfasis).
  final Color? borderColor;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final ink = color ?? c.ink;
    return Pressable(
      onTap: busy ? null : onPressed,
      builder: (context, pressed) {
        final text = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VText.ui(fontSize, weight: weight, color: ink),
        );
        return Opacity(
          opacity: onPressed == null ? 0.4 : 1,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: pressed ? c.ink : (borderColor ?? c.lineStrong),
              ),
            ),
            child: center
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leading != null) ...[leading!, const SizedBox(width: 8)],
                      Flexible(child: text),
                      if (busy) ...[const SizedBox(width: 10), VSpinner(color: ink)],
                    ],
                  )
                : Row(
                    children: [
                      if (leading != null) ...[leading!, const SizedBox(width: 8)],
                      Expanded(child: text),
                      if (busy)
                        VSpinner(color: ink)
                      else if (trailing != null)
                        Text(trailing!, style: VText.ui(fontSize, weight: weight, color: c.ink4)),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Enlace de texto subrayado ("Crear cuenta", "¿Olvidaste tu
/// contraseña?"). La raya es el borde de la caja del texto, que en Archivo
/// queda 3 px bajo la línea base, como `text-underline-offset: 3px`. Para
/// una sola línea: dentro de un párrafo que se parte, usar
/// `TextDecoration.underline`.
class VTextLink extends StatelessWidget {
  const VTextLink(this.text, {super.key, required this.onTap, this.style});

  final String text;
  final VoidCallback? onTap;

  /// Por defecto, 14 en tinta.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final textStyle = (style ?? VText.ui(14, color: c.ink)).copyWith(height: null);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Opacity(
        opacity: pressed ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: textStyle.color ?? c.ink)),
          ),
          // El borde se pinta dentro de la caja: 1 px de aire lo deja debajo
          // del texto, donde lo pone el navegador.
          child: Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(text, style: textStyle),
          ),
        ),
      ),
    );
  }
}

/// Cómo se ve un botón cuadrado de ícono.
enum VIconButtonStyle {
  /// Borde de 1 px sobre el fondo (volver, compartir en pantallas lisas).
  bordered,

  /// Relleno translúcido sobre una foto (la portada, el banner).
  filled,

  /// Solo el ícono (la campana del inicio).
  plain,
}

/// Botón cuadrado de 40×40 con un ícono de trazo de 18.
class VIconButton extends StatelessWidget {
  const VIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.style = VIconButtonStyle.bordered,
    this.size = 40,
    this.iconSize = 18,
    this.fill,
    this.tooltip,
    this.child,
  });

  final VIcon icon;
  final VoidCallback? onTap;
  final VIconButtonStyle style;
  final double size;
  final double iconSize;

  /// Otro relleno para `filled` (las listas usan la tinta al 45 %).
  final Color? fill;
  final String? tooltip;

  /// Contenido propio en lugar del ícono (la campana con su punto).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final button = Pressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedOpacity(
        duration: const Duration(milliseconds: 90),
        opacity: pressed ? 0.55 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: switch (style) {
              VIconButtonStyle.filled => fill ?? c.overButton,
              _ => Colors.transparent,
            },
            border: style == VIconButtonStyle.bordered
                ? Border.all(color: c.buttonLine)
                : null,
          ),
          alignment: Alignment.center,
          child: child ?? VIconView(icon, size: iconSize, color: c.ink),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Semantics(label: tooltip, button: true, child: button);
  }
}

/// El "cargando" del rediseño: un círculo de 16 con borde de 2 al que le
/// falta el cuarto de arriba, girando a 0,8 s por vuelta.
class VSpinner extends StatefulWidget {
  const VSpinner({super.key, this.size = 16, this.color, this.strokeWidth = 2});

  final double size;

  /// Por defecto, tinta.
  final Color? color;
  final double strokeWidth;

  /// Cuánto tarda una vuelta.
  static const Duration turn = Duration(milliseconds: 800);

  @override
  State<VSpinner> createState() => _VSpinnerState();
}

class _VSpinnerState extends State<VSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _turn =
      AnimationController(vsync: this, duration: VSpinner.turn)..repeat();

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? VColors.of(context).ink;
    return RotationTransition(
      turns: _turn,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(color, widget.strokeWidth),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    // Tres cuartos de círculo: falta el de arriba, como un borde con
    // `border-top-color: transparent`.
    canvas.drawArc(
      (Offset.zero & size).deflate(strokeWidth / 2),
      -math.pi / 4,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.color != color || old.strokeWidth != strokeWidth;
}
