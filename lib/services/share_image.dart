import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../share_cards/share_card_data.dart';

/// Convierte una tarjeta para compartir en PNG. La tarjeta va dentro de un
/// `RepaintBoundary` a su tamaño lógico (la vista previa de la hoja la
/// escala por fuera) y se captura a 3×: 1080×1920 o 1080×1080.
class ShareImage {
  ShareImage._();

  /// Espera a que carguen las imágenes que la tarjeta va a dibujar, para
  /// que salgan en la captura (y sin el fundido de `AlbumCover`). Una que no
  /// carga se queda en `surface`; no detiene nada.
  static Future<void> precache(BuildContext context, Iterable<String?> urls) {
    final unique = {
      for (final u in urls)
        if (u != null && u.isNotEmpty) u,
    };
    return Future.wait([
      for (final u in unique)
        precacheImage(NetworkImage(u), context, onError: (_, _) {})
            .timeout(const Duration(seconds: 12), onTimeout: () {}),
    ]);
  }

  /// El PNG de lo que hay dentro del `RepaintBoundary` de `key`.
  static Future<Uint8List> capture(GlobalKey key, {double pixelRatio = shareCardPixelRatio}) async {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      throw StateError('share card not mounted');
    }
    // Si acaba de montarse o cambiar, que termine de pintarse (en release no
    // existe `debugNeedsPaint`, así que se espera siempre; sin cuadro
    // pendiente vuelve enseguida).
    await WidgetsBinding.instance.endOfFrame;
    final image = await object.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('png encoding failed');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
