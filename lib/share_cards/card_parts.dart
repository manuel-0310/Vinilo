import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_sections.dart';
import 'share_card_data.dart';

/// Marco de una tarjeta para compartir: tamaño fijo (360×640 o 360×360), el
/// fondo y el tema oscuro con el énfasis de quien comparte. Las tarjetas son
/// imágenes: se ven oscuras aunque la app esté en claro, y el texto no
/// cambia con el tamaño de letra del teléfono.
class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({
    super.key,
    required this.format,
    required this.accent,
    required this.child,
    this.background,
    this.padding = const EdgeInsets.all(28),
  });

  final ShareCardFormat format;
  final Color accent;

  /// Sin fondo, el de la app (`bg`).
  final Color? background;
  final EdgeInsets padding;
  final Widget child;

  static final Map<int, ThemeData> _themes = {};

  static ThemeData themeFor(Color accent) => _themes.putIfAbsent(
        accent.toARGB32(),
        () => buildViniloTheme(ViniloPalette.dark.withAccent(accent)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = themeFor(accent);
    final p = theme.extension<ViniloPalette>()!;
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Theme(
        data: theme,
        child: DefaultTextStyle(
          style: VText.ui(14, color: p.ink),
          child: SizedBox.fromSize(
            size: format.size,
            child: ColoredBox(
              color: background ?? p.bg,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// "VINILO" con la raya de 12×3 del pie.
class CardLogo extends StatelessWidget {
  const CardLogo({super.key, this.size = 22, this.color, this.barColor});

  final double size;
  final Color? color;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('VINILO', style: VText.display(size, weight: 900, height: 0.8, tracking: 0, color: color ?? c.ink)),
        const SizedBox(width: 6),
        Container(width: 12, height: 3, color: barColor ?? c.accent),
      ],
    );
  }
}

/// El pie: línea arriba, lo de la izquierda y el logo a la derecha.
class CardFooter extends StatelessWidget {
  const CardFooter({
    super.key,
    required this.leading,
    this.lineColor,
    this.top = 14,
    this.logoSize = 22,
    this.logoColor,
    this.barColor,
  });

  final Widget leading;

  /// Por defecto, tinta al 20 %.
  final Color? lineColor;
  final double top;
  final double logoSize;
  final Color? logoColor;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: lineColor ?? c.inkA(0.2)))),
      child: Row(
        children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: leading)),
          const SizedBox(width: 12),
          CardLogo(size: logoSize, color: logoColor, barColor: barColor),
        ],
      ),
    );
  }
}

/// Avatar de 24 y @usuario en mono.
class CardHandle extends StatelessWidget {
  const CardHandle({super.key, required this.person, this.avatar = true, this.size = 10});

  final CardPerson person;
  final bool avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (avatar) ...[
          UserAvatar(name: person.name, color: person.color, url: person.avatarUrl, size: 24),
          const SizedBox(width: 8),
        ],
        Flexible(child: VMono(person.label, size: size, tracking: 0.08, color: c.ink, maxLines: 1)),
      ],
    );
  }
}

/// Portada cuadrada (sin cargar, `surface`).
class CardCover extends StatelessWidget {
  const CardCover({super.key, required this.url, this.size});

  final String? url;
  final double? size;

  @override
  Widget build(BuildContext context) => AlbumCover(url: url, size: size);
}

/// Rejilla de portadas de `columns` columnas con separación de 4.
class CardCoverGrid extends StatelessWidget {
  const CardCoverGrid({super.key, required this.covers, required this.columns, this.gap = 4});

  final List<String?> covers;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final rows = (covers.length + columns - 1) ~/ columns;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Row(
            children: [
              for (var k = 0; k < columns; k++) ...[
                if (k > 0) SizedBox(width: gap),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: r * columns + k < covers.length && covers[r * columns + k] != null
                        ? CardCover(url: covers[r * columns + k])
                        : ColoredBox(color: c.inkA(0.06)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// "21 sep 2026" (VMono lo pasa a mayúsculas).
String cardDate(DateTime date, String locale) =>
    DateFormat('d MMM y', locale).format(date).replaceAll('.', '');

/// El número de una nota o un promedio en las tarjetas.
TextStyle cardNumber(double size, {Color? color, int weight = 700}) =>
    VText.display(size, weight: weight, height: 0.8, tracking: 0, color: color);
