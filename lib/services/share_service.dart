import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abre la hoja de compartir del sistema con un texto y un enlace, sin
/// paquetes: canal `vinilo/share` (`UIActivityViewController` en
/// `AppDelegate.swift`, `Intent.ACTION_SEND` en `MainActivity.kt`). En web,
/// o si el canal no responde, copia el texto y el enlace al portapapeles y
/// devuelve false para que la pantalla avise "Enlace copiado".
class ShareService {
  ShareService._();

  static const MethodChannel _channel = MethodChannel('vinilo/share');

  /// `origin` es el rectángulo del botón (en pantalla), para anclar la hoja
  /// en iPad.
  static Future<bool> share(String text, Uri url, {Rect? origin}) async {
    final native = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
    if (native) {
      try {
        await _channel.invokeMethod<bool>('share', {
          'text': text,
          'url': url.toString(),
          if (origin != null) ...{
            'x': origin.left,
            'y': origin.top,
            'w': origin.width,
            'h': origin.height,
          },
        });
        return true;
      } on MissingPluginException {
        // Sin el canal (por ejemplo, una app sin relanzar): se copia.
      } on PlatformException {
        // Igual: mejor copiar que no hacer nada.
      }
    }
    await Clipboard.setData(ClipboardData(text: '$text\n$url'));
    return false;
  }
}
