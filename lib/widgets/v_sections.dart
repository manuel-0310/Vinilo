import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vinilo_theme.dart';
import 'v_buttons.dart';
import 'v_icons.dart';

/// Etiqueta en IBM Plex Mono y en mayúsculas ("POPULAR ESTA SEMANA"). El
/// texto se escribe normal en los ARB y aquí se pasa a mayúsculas.
class VMono extends StatelessWidget {
  const VMono(
    this.text, {
    super.key,
    this.size = 10.5,
    this.color,
    this.weight = 500,
    this.tracking = 0.08,
    this.height,
    this.align,
    this.maxLines,
    this.uppercase = true,
  });

  final String text;
  final double size;

  /// Por defecto `ink3`, el de las etiquetas.
  final Color? color;
  final int weight;
  final double tracking;
  final double? height;
  final TextAlign? align;
  final int? maxLines;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Text(
      uppercase ? text.toUpperCase() : text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: VText.mono(
        size,
        color: color ?? c.ink3,
        weight: weight,
        tracking: tracking,
        height: height,
      ),
    );
  }
}

/// Encabezado de sección: etiqueta mono a la izquierda, acción a la derecha
/// (en énfasis si `accentAction`), línea arriba y relleno de 10.
class VSectionHeader extends StatelessWidget {
  const VSectionHeader(
    this.label, {
    super.key,
    this.action,
    this.onAction,
    this.accentAction = true,
    this.padding = const EdgeInsets.symmetric(horizontal: VSpace.page, vertical: 10),
    this.line = true,
    this.actionKey,
  });

  final String label;

  /// Texto de la derecha: "Ver todo" (acción) o un dato ("2 nuevas").
  final String? action;
  final VoidCallback? onAction;
  final bool accentAction;
  final EdgeInsets padding;
  final bool line;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: padding,
      decoration: line
          ? BoxDecoration(border: Border(top: BorderSide(color: c.line)))
          : null,
      child: Row(
        children: [
          Expanded(child: VMono(label, maxLines: 1)),
          if (action != null)
            Pressable(
              key: actionKey,
              onTap: onAction,
              builder: (context, pressed) => Opacity(
                opacity: pressed ? 0.6 : 1,
                child: VMono(
                  action!,
                  color: onAction != null && accentAction ? c.accentText : c.ink3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Título de un bloque ("Calificado por", "Diario"): 30 px condensado al
/// 70 %, un subtítulo y, a la derecha, una acción mono en énfasis.
class VBlockTitle extends StatelessWidget {
  const VBlockTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(VSpace.page, 30, VSpace.page, 0),
    this.actionKey,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  /// Algo a la derecha en lugar de la acción ("Promedio amigos 9,0").
  final Widget? trailing;
  final EdgeInsets padding;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.display(30, weight: 700, stretch: 70, height: 1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: VText.ui(13.5, color: c.ink3)),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (action != null)
            Pressable(
              key: actionKey,
              onTap: onAction,
              builder: (context, pressed) => Opacity(
                opacity: pressed ? 0.6 : 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 3),
                  child: VMono(action!, color: c.accentText),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Encabezado de una pantalla empujada (Notificaciones, Popular, Ver
/// todos): volver con borde, el título condensado de 50, una etiqueta mono
/// debajo ("2 sin leer") y, a la derecha, una acción mono ("Borrar todas").
/// Va debajo de la barra de estado: quien lo usa pone el `SafeArea`.
class VPageHeader extends StatelessWidget {
  const VPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleKey,
    this.action,
    this.onAction,
    this.actionKey,
    this.titleSize = 50,
    this.titleKey,
    this.topTrailing,
  });

  final String title;
  final String? subtitle;
  final Key? subtitleKey;
  final String? action;
  final VoidCallback? onAction;
  final Key? actionKey;
  final double titleSize;
  final Key? titleKey;

  /// Algo a la derecha del botón de volver (compartir en el hilo).
  final Widget? topTrailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              VIconButton(
                key: const ValueKey('back'),
                icon: VIcon.back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              ?topTrailing,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      key: titleKey,
                      style: VText.display(titleSize, weight: 800, height: 0.88, tracking: 0),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      VMono(subtitle!, key: subtitleKey),
                    ],
                  ],
                ),
              ),
              if (action != null)
                Pressable(
                  key: actionKey,
                  onTap: onAction,
                  builder: (context, pressed) => Opacity(
                    opacity: pressed ? 0.6 : 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                      child: VMono(action!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pestañas de texto con subrayado de 2 px en énfasis (no un control
/// segmentado): la activa en 600 y tinta, las demás en 500 y apagadas, y
/// una línea de 1 px debajo de todo.
class VTabs extends StatelessWidget {
  const VTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.keys,
    this.padding = const EdgeInsets.symmetric(horizontal: VSpace.page),
    this.gap = 24,
    this.fontSize = 15,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<String>? keys;
  final EdgeInsets padding;
  final double gap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(height: 1, color: c.line),
        ),
        Padding(
          padding: padding,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                GestureDetector(
                  key: keys == null ? null : ValueKey(keys![i]),
                  behavior: HitTestBehavior.opaque,
                  onTap: i == selected ? null : () => onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: i == selected ? c.accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: VText.ui(
                        fontSize,
                        weight: i == selected ? 600 : 500,
                        color: i == selected ? c.ink : c.inactive,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Estado vacío: solo texto (título condensado y explicación), sin
/// ilustraciones.
class VEmptyState extends StatelessWidget {
  const VEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(VSpace.page, 24, VSpace.page, 24),
  });

  final String title;
  final String message;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VText.display(30, weight: 700, stretch: 70, height: 1)),
          const SizedBox(height: 8),
          Text(message, style: VText.ui(14, color: c.ink2, height: 1.45)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Bloque plano mientras algo carga: late de opacidad, sin brillos.
class VSkeleton extends StatelessWidget {
  const VSkeleton({super.key, this.width, this.height, this.circle = false});

  final double? width;
  final double? height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: 0.07),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.55, end: 1, duration: 900.ms, curve: Curves.easeInOut);
  }
}
