import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Compartir sin paquetes: canal `vinilo/share` (`ShareChannel` en
/// `AppDelegate.swift`, `MainActivity.kt` + `ShareImageProvider.kt`).
/// - `share`: hoja del sistema con texto y enlace. En web, o si el canal no
///   responde, copia el texto y el enlace y devuelve false ("Enlace
///   copiado").
/// - `shareImage`, `instagramStory` y `saveImage`: las imágenes de la hoja
///   "Compartir" (PNG a 3×).
class ShareService {
  ShareService._();

  static const MethodChannel _channel = MethodChannel('vinilo/share');

  /// App ID de Meta para las historias de Instagram
  /// (`--dart-define=META_APP_ID=…`). Sin él, "Historias" abre la hoja del
  /// sistema, donde Instagram también ofrece su historia.
  static const String metaAppId = String.fromEnvironment('META_APP_ID');

  static bool get _native =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Si esta plataforma puede compartir imágenes (en web, solo el enlace).
  static bool get canShareImages => _native;

  static Map<String, Object> _origin(Rect? origin) => {
        if (origin != null) ...{
          'x': origin.left,
          'y': origin.top,
          'w': origin.width,
          'h': origin.height,
        },
      };

  /// `origin` es el rectángulo del botón (en pantalla), para anclar la hoja
  /// en iPad.
  static Future<bool> share(String text, Uri url, {Rect? origin}) async {
    if (_native) {
      try {
        await _channel.invokeMethod<bool>('share', {
          'text': text,
          'url': url.toString(),
          ..._origin(origin),
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

  /// La hoja del sistema con la imagen, el texto y el enlace. Lanza
  /// `ShareImageException` si no se pudo abrir.
  static Future<void> shareImage(Uint8List png, String text, Uri url, {Rect? origin}) async {
    final ok = await _call('shareImage', {'png': png, 'text': text, 'url': url.toString(), ..._origin(origin)});
    if (ok != true) throw const ShareImageException(ShareImageError.failed);
  }

  /// El editor de historias de Instagram con la imagen de fondo. Devuelve
  /// false si no se puede (sin App ID o sin Instagram): entonces se usa
  /// `shareImage`.
  static Future<bool> instagramStory(Uint8List png) async {
    if (metaAppId.isEmpty && defaultTargetPlatform == TargetPlatform.iOS) return false;
    final ok = await _call('instagramStory', {'png': png, 'appId': metaAppId});
    return ok == true;
  }

  /// Guarda la imagen en Fotos (iOS) o en Imágenes/Vinilo (Android).
  static Future<void> saveImage(Uint8List png) async {
    await _call('saveImage', {'png': png});
  }

  static Future<bool?> _call(String method, Map<String, Object> args) async {
    if (!_native) throw const ShareImageException(ShareImageError.unsupported);
    try {
      return await _channel.invokeMethod<bool>(method, args);
    } on MissingPluginException {
      throw const ShareImageException(ShareImageError.unsupported);
    } on PlatformException catch (e) {
      throw ShareImageException(e.code == 'denied' ? ShareImageError.denied : ShareImageError.failed);
    }
  }
}

enum ShareImageError {
  /// Sin permiso para guardar en Fotos.
  denied,

  /// La app no tiene el canal (web, o sin relanzar tras actualizar).
  unsupported,
  failed,
}

/// Error tipado de las imágenes para compartir (el texto lo pone la hoja).
class ShareImageException implements Exception {
  const ShareImageException(this.error);

  final ShareImageError error;

  @override
  String toString() => 'ShareImageException($error)';
}
