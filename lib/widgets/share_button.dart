import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/share_service.dart';
import '../util/share_links.dart';
import 'share_sheet.dart';
import 'v_buttons.dart';
import 'v_icons.dart';

/// Botón cuadrado de 40 para compartir, como los demás de las cabeceras:
/// relleno translúcido sobre una foto (`filled`, el de siempre) o con borde
/// sobre el fondo liso. `message` arma el texto y el enlace en el idioma de
/// la app al tocarlo. Con `cards` (y alguna tarjeta), abre la hoja
/// "Compartir" con las imágenes; sin ellas, la hoja del sistema.
class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.message,
    this.cards,
    this.style = VIconButtonStyle.filled,
    this.fill,
  });

  final ShareMessage Function(AppLocalizations l) message;

  /// Las tarjetas para compartir como imagen (se arman al tocar).
  final FutureOr<List<ShareCardSpec>> Function()? cards;
  final VIconButtonStyle style;

  /// Otro relleno para `filled`.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Builder(
      // El `context` de dentro es el del botón: la hoja del sistema se ancla
      // a él en el iPad.
      builder: (context) => VIconButton(
        icon: VIcon.share,
        style: style,
        fill: fill,
        tooltip: context.l10n.shareAction,
        onTap: () async {
          final specs = await cards?.call() ?? const <ShareCardSpec>[];
          if (!context.mounted) return;
          if (specs.isEmpty) {
            shareMessage(context, message(context.l10n));
          } else {
            openShare(context, cards: specs, message: message);
          }
        },
      ),
    );
  }
}

/// Abre la hoja de compartir del sistema anclada al widget de `context`; si
/// no se puede (web), copia el enlace y lo avisa.
Future<void> shareMessage(BuildContext context, ShareMessage message) async {
  HapticFeedback.selectionClick();
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final shared = await ShareService.share(message.text, message.url, origin: origin);
  if (!shared) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.linkCopied), duration: const Duration(seconds: 2)),
    );
  }
}
