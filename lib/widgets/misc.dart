import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vinilo_theme.dart';
import 'vinyl_disc.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.top = 30,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final double top;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(VSpace.page, top, VSpace.page, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.display(28, height: 1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: VText.ui(13, color: c.text2)),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: (c.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.labelColor,
  });

  final String title;
  final String message;
  final Widget? action;

  /// Color de la etiqueta del vinilo; por defecto el acento del tema.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
      child: Column(
        children: [
          VinylDisc(size: 72, labelColor: labelColor ?? c.accent)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: VText.display(28, height: 1.05),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: VText.ui(14, color: c.text2, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: c.scrim.withValues(alpha: c.isDark ? 0.32 : 0.55),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 20, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resplandor radial que tiñe la parte alta de una pantalla con el color
/// dominante de una portada (o el color de un perfil). Va detrás del
/// encabezado de un CustomScrollView como hijo Positioned de un Stack
/// (`top: -AmbientGlow.bleed, bottom: 0`): así sube con el encabezado al
/// hacer scroll y se desvanece antes de que este termine. `bleed` es lo que
/// sobresale por arriba para cubrir el rebote del scroll.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key, required this.color, this.focus = 70});

  static const double bleed = 300;

  final Color color;

  /// Distancia desde el borde superior de la pantalla al centro del resplandor.
  final double focus;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          if (!h.isFinite || h <= 0) return const SizedBox.shrink();
          final centerPx = bleed + focus;
          final reach = math.max(40.0, h - centerPx);
          final shortest = math.min(w, h);
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              final c = value ?? color;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, 2 * centerPx / h - 1),
                    radius: reach / shortest,
                    colors: [
                      c.withValues(alpha: 0.62),
                      c.withValues(alpha: 0.22),
                      c.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              );
            },
          );
        },
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final Widget child;

  /// Fondo de la píldora; por defecto la segunda superficie del tema.
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      color: color ?? c.surface2,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Selector de secciones en píldoras (en el perfil: "Perfil" y "Listas").
/// La elegida va rellena con el color de énfasis. `keys` da una llave a
/// cada píldora para el driver de pruebas.
class SectionSwitch extends StatelessWidget {
  const SectionSwitch({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.keys,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<String>? keys;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                key: keys == null ? null : ValueKey(keys![i]),
                behavior: HitTestBehavior.opaque,
                onTap: i == selected ? null : () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selected ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: VText.ui(
                        14,
                        weight: 700,
                        color: i == selected ? c.onAccent : c.text2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Píldora que se elige o no (filtros del diario y de las listas). `color`
/// cambia el tono de la elegida (por defecto el énfasis).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final accent = color ?? c.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.16) : c.surface2,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.7) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: VText.ui(13, weight: 700, color: selected ? accent : c.text2),
          ),
        ),
      ),
    );
  }
}
