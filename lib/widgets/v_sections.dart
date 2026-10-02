import 'package:flutter/material.dart';

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
/// (en énfasis si `accentAction`), línea arriba y relleno de 10. Con `big`,
/// la etiqueta es un subtítulo condensado de 28 (las secciones del inicio).
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
    this.big = false,
  });

  final String label;
  final bool big;

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
        crossAxisAlignment: big ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: big
                ? Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.display(28, weight: 700, stretch: 70, height: 1),
                  )
                : VMono(label, maxLines: 1),
          ),
          if (action != null)
            Pressable(
              key: actionKey,
              onTap: onAction,
              builder: (context, pressed) => Opacity(
                opacity: pressed ? 0.6 : 1,
                child: Padding(
                  padding: EdgeInsets.only(left: 12, bottom: big ? 3 : 0),
                  child: VMono(
                    action!,
                    color: onAction != null && accentAction ? c.accentText : c.ink3,
                  ),
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

/// Bloque plano mientras algo carga, con la forma de lo que va a llegar
/// (`soft` para las líneas secundarias, un punto más apagado). El brillo que
/// lo cruza lo pone `VShimmer`: si el bloque no está dentro de uno, trae el
/// suyo.
class VSkeleton extends StatelessWidget {
  const VSkeleton({
    super.key,
    this.width,
    this.height,
    this.circle = false,
    this.soft = false,
  });

  final double? width;
  final double? height;
  final bool circle;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: soft ? c.skeletonSoft : c.skeleton,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
    if (_ShimmerScope.around(context)) return block;
    return VShimmer(circle: circle, child: block);
  }
}

/// El brillo de las cargas: una franja clara que cruza de izquierda a
/// derecha en 1,4 s, en bucle, por encima de todo lo que envuelve (un grupo
/// de `VSkeleton` comparte así un solo brillo, como en el prototipo).
class VShimmer extends StatefulWidget {
  const VShimmer({super.key, required this.child, this.circle = false});

  final Widget child;

  /// Recorta el brillo en círculo (un avatar suelto).
  final bool circle;

  /// Cuánto tarda en cruzar.
  static const Duration period = Duration(milliseconds: 1400);

  @override
  State<VShimmer> createState() => _VShimmerState();
}

class _VShimmerState extends State<VShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: VShimmer.period)..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final clear = c.ink.withValues(alpha: 0);
    final band = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, child) => FractionalTranslation(
          // De −100 % a 100 % del ancho, con arranque y llegada suaves.
          translation: Offset(-1 + 2 * Curves.easeInOut.transform(_sweep.value), 0),
          child: child,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [clear, c.inkA(0.06), clear]),
          ),
        ),
      ),
    );
    return _ShimmerScope(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: widget.circle ? ClipOval(child: band) : ClipRect(child: band),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca que los bloques de dentro ya tienen brillo.
class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required super.child});

  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ShimmerScope>() != null;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => false;
}

/// Un filtro de texto ("Populares", "Este año"): 14, el elegido en tinta
/// con una raya de 1 px debajo y los demás apagados. Lleva 12 de aire
/// arriba y abajo para que el toque mida 44; quien lo usa los descuenta.
class VFilterOption extends StatelessWidget {
  const VFilterOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// El aire de arriba y de abajo que agranda el toque.
  static const double touchPad = 12;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: touchPad),
        child: Container(
          padding: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: selected ? c.ink : Colors.transparent),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: VText.ui(14, weight: 500, color: selected ? c.ink : c.inactive),
          ),
        ),
      ),
    );
  }
}

/// Una fila de filtros de texto, separados 18; si no caben, se desliza de
/// lado. El alto incluye los 12 de aire de cada lado (`VFilterOption`).
class VTextFilters extends StatelessWidget {
  const VTextFilters({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.keys,
    this.padding = const EdgeInsets.symmetric(horizontal: VSpace.page),
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<String>? keys;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            VFilterOption(
              key: keys == null ? null : ValueKey(keys![i]),
              label: labels[i],
              selected: i == selected,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}
