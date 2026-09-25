import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Hoja modal con el carácter de la app: superficie, esquinas redondeadas,
/// asa, un título en serif y el contenido debajo. Sube con el teclado.
/// Con `height` ocupa esa fracción de la pantalla y el contenido se
/// desplaza dentro; sin ella se ajusta a su contenido.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.height,
    this.trailing,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Fracción del alto de la pantalla (0.85, por ejemplo).
  final double? height;

  /// Algo a la derecha del título (un contador, un botón).
  final Widget? trailing;

  /// Si es false, `child` se coloca en un `Expanded` y se encarga él de
  /// desplazarse (listas largas).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.display(30, height: 1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: VText.ui(13, color: c.text2)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    final Widget body = scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            physics: const BouncingScrollPhysics(),
            child: child,
          )
        : child;

    final column = Column(
      mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const SheetHandle(),
        header,
        // Ajustada a su contenido, el cuerpo se desplaza cuando no cabe en
        // la pantalla (con la biografía, "Editar perfil" ya no cabía y el
        // botón de guardar quedaba fuera).
        if (height != null)
          Expanded(child: body)
        else if (scrollable)
          Flexible(child: body)
        else
          body,
      ],
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: height == null ? null : MediaQuery.sizeOf(context).height * height!,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: column,
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: c.text3.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Abre una hoja modal transparente por fuera (la hoja pinta su fondo).
Future<T?> showVSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Una opción de una hoja de acciones: icono, texto y una línea de ayuda.
class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
    this.danger = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = danger ? c.danger : c.text;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: c.surface2,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: danger ? c.danger : c.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: VText.ui(15, weight: 700, color: color)),
                      if (hint != null)
                        Text(hint!, style: VText.ui(12, color: c.text2, height: 1.3)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.text3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
