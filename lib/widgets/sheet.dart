import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// Hoja inferior del rediseño: fondo `sheet`, línea de 1 px arriba, sin
/// esquinas redondeadas, asa de 40×4, una etiqueta mono opcional
/// ("Canción · Tabú"), un título condensado de 46 y el contenido. Sube con
/// el teclado. Con `height` ocupa esa fracción de la pantalla y el
/// contenido se desplaza dentro; sin ella se ajusta a su contenido.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.overline,
    this.height,
    this.trailing,
    this.footer,
    this.scrollable = true,
    this.titleSize = 46,
  });

  final String title;
  final String? subtitle;

  /// Etiqueta mono sobre el título ("Canción · Tabú").
  final String? overline;
  final Widget child;

  /// Fracción del alto de la pantalla (0.85, por ejemplo).
  final double? height;

  /// Algo a la derecha del título (un contador, un botón).
  final Widget? trailing;

  /// Botón fijo abajo ("Crear lista →"), fuera de la parte que se desplaza.
  final Widget? footer;

  /// Si es false, `child` se coloca en un `Expanded` y se encarga él de
  /// desplazarse (listas largas).
  final bool scrollable;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(VSpace.page, 22, VSpace.page, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  VMono(overline!, maxLines: 1),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: VText.display(titleSize, height: 0.9),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: VText.ui(14, color: c.ink2, height: 1.4)),
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
            padding: EdgeInsets.fromLTRB(
              VSpace.page,
              20,
              VSpace.page,
              footer == null ? 24 + bottomInset : 20,
            ),
            physics: const BouncingScrollPhysics(),
            child: child,
          )
        : child;

    final column = Column(
      mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
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
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 20 + bottomInset),
            child: footer,
          ),
      ],
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: height == null ? null : MediaQuery.sizeOf(context).height * height!,
        decoration: BoxDecoration(
          color: c.sheet,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: column,
      ),
    );
  }
}

/// Asa de la hoja: 40×4, tinta al 30 %, sin redondear.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Center(
      child: Container(width: 40, height: 4, color: c.ink.withValues(alpha: 0.3)),
    );
  }
}

/// Abre una hoja inferior con el velo del rediseño (la hoja pinta su fondo).
Future<T?> showVSheet<T>(BuildContext context, WidgetBuilder builder) {
  final c = VColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    shape: const RoundedRectangleBorder(),
    builder: builder,
  );
}

/// Pide confirmación en una hoja (en lugar de un diálogo): el botón que
/// confirma (en `danger` si borra algo) y "Cancelar". Devuelve true si se
/// confirmó.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool danger = false,
  Key? confirmKey,
}) async {
  final ok = await showVSheet<bool>(
    context,
    (ctx) {
      final c = VColors.of(ctx);
      return SheetScaffold(
        title: title,
        subtitle: message,
        titleSize: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (danger)
              VPrimaryButton.tone(
                key: confirmKey,
                label: confirmLabel,
                color: c.danger,
                onPressed: () => Navigator.of(ctx).pop(true),
              )
            else
              VPrimaryButton(
                key: confirmKey,
                label: confirmLabel,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            const SizedBox(height: 8),
            VSecondaryButton(
              label: ctx.l10n.cancel,
              center: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return ok ?? false;
}

/// Una opción de una hoja de acciones: fila plana con línea debajo, ícono,
/// texto y una línea de ayuda.
class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    this.icon,
    this.vicon,
    required this.label,
    required this.onTap,
    this.hint,
    this.danger = false,
    this.enabled = true,
  });

  /// Ícono de Material (lo que usan las hojas que aún no se rediseñaron).
  final IconData? icon;

  /// Ícono de trazo del rediseño; si está, manda sobre `icon`.
  final VIcon? vicon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = danger ? c.danger : c.ink;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        onTap: enabled ? onTap : null,
        builder: (context, pressed) => Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: pressed ? c.ink.withValues(alpha: 0.04) : Colors.transparent,
            border: Border(bottom: BorderSide(color: c.lineSoft)),
          ),
          child: Row(
            children: [
              if (vicon != null)
                VIconView(vicon!, size: 20, color: danger ? c.danger : c.ink2)
              else if (icon != null)
                Icon(icon, size: 20, color: danger ? c.danger : c.ink2),
              if (vicon != null || icon != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: VText.ui(16, weight: 600, color: color)),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(hint!, style: VText.ui(12.5, color: c.ink3, height: 1.3)),
                    ],
                  ],
                ),
              ),
              VIconView(VIcon.chevronRight, size: 16, color: c.ink4),
            ],
          ),
        ),
      ),
    );
  }
}
