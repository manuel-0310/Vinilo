import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';
import 'v_buttons.dart';
import 'v_sections.dart';

// Widgets del diseño anterior que todavía usan las pantallas sin
// rediseñar. Conservan su nombre y sus parámetros, pero ya se dibujan con
// el sistema nuevo; se borran al terminar el rediseño.

/// Título de sección: ahora es un `VBlockTitle` (30 px condensado).
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: VBlockTitle(
        title,
        subtitle: subtitle,
        trailing: action,
        padding: EdgeInsets.fromLTRB(VSpace.page, top, VSpace.page, 0),
      ),
    );
  }
}

/// Bloque de carga: plano, sin esquinas ni brillo (`VSkeleton`).
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 0,
  });

  final double? width;
  final double? height;

  /// Se ignora: el rediseño no tiene esquinas redondeadas.
  final double radius;

  @override
  Widget build(BuildContext context) => VSkeleton(width: width, height: height);
}

/// Estado vacío: solo texto (`VEmptyState`), sin el vinilo de antes.
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

  /// Se ignora (era el color de la etiqueta del vinilo).
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(title: title, message: message, action: action);
  }
}

/// Botón redondo de vidrio de antes: ahora es un botón cuadrado de 40 con
/// el relleno translúcido que va sobre las fotos.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedOpacity(
        duration: const Duration(milliseconds: 90),
        opacity: pressed ? 0.55 : 1,
        child: Container(
          width: size,
          height: size,
          color: c.overButton,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: c.ink),
        ),
      ),
    );
  }
}

/// El resplandor de antes: el rediseño no tiene gradientes, así que ya no
/// dibuja nada. `bleed` se conserva para las pantallas que lo posicionan.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key, required this.color, this.focus = 70});

  static const double bleed = 300;

  final Color color;
  final double focus;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Lo que antes era una píldora: una caja de borde recto de 1 px.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final Widget child;

  /// Fondo; por defecto, ninguno.
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: pressed ? c.ink : c.lineStrong),
        ),
        child: child,
      ),
    );
  }
}

/// Selector de secciones: ahora son pestañas de texto subrayadas
/// (`VTabs`).
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
    return VTabs(
      labels: labels,
      selected: selected,
      onChanged: onChanged,
      keys: keys,
      padding: EdgeInsets.zero,
    );
  }
}

/// Opción de un filtro: texto de 14; la elegida en tinta con una línea de
/// 1 px debajo, las demás apagadas (los filtros de listas del prototipo).
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

  /// Color de la elegida (por defecto, tinta).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final active = color ?? c.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: selected ? active : Colors.transparent),
            ),
          ),
          child: Text(
            label,
            style: VText.ui(14, weight: 500, color: selected ? active : c.inactive),
          ),
        ),
      ),
    );
  }
}
