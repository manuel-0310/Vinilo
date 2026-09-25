import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/share_service.dart';
import '../util/share_links.dart';
import 'misc.dart';

/// Botón redondo de vidrio para compartir, como los demás de las cabeceras.
/// `message` arma el texto y el enlace en el idioma de la app al tocarlo.
class ShareButton extends StatelessWidget {
  const ShareButton({super.key, required this.message});

  final ShareMessage Function(AppLocalizations l) message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.shareAction,
      child: GlassIconButton(
        icon: Icons.ios_share_rounded,
        onTap: () => shareMessage(context, message(context.l10n)),
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
