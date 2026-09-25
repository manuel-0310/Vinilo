import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Saca el color dominante de una portada, tal cual (sin aclararlo ni
/// saturarlo): el disco lo pasa por `coverTone` para la nota y el artista, y
/// por su cuenta para las celdas de la regla. Una portada gris devuelve un
/// gris. No usa paquetes nativos: reutiliza la imagen ya decodificada por
/// Flutter.
class PaletteService {
  final Map<String, Color> _cache = {};

  Future<Color?> dominant(String? url) async {
    if (url == null || url.isEmpty) return null;
    final cached = _cache[url];
    if (cached != null) return cached;
    try {
      final image = await _load(url);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = image.width;
      final height = image.height;
      image.dispose();
      if (bytes == null) return null;
      final color = pick(bytes, width, height);
      if (color != null) _cache[url] = color;
      return color;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image> _load(String url) {
    final completer = Completer<ui.Image>();
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(const Duration(seconds: 12));
  }

  /// El color dominante de unos píxeles RGBA (público para las pruebas).
  @visibleForTesting
  static Color? pick(ByteData data, int width, int height) {
    // 24 tonalidades más un grupo aparte para los grises, que si no se
    // mezclarían con los rojos (su tonalidad es 0).
    const hueBuckets = 24;
    const bucketCount = hueBuckets + 1;
    final weights = List<double>.filled(bucketCount, 0);
    final reds = List<double>.filled(bucketCount, 0);
    final greens = List<double>.filled(bucketCount, 0);
    final blues = List<double>.filled(bucketCount, 0);

    final stride = math.max(1, math.sqrt(width * height / 4000).floor());
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final i = (y * width + x) * 4;
        if (i + 3 >= data.lengthInBytes) continue;
        final r = data.getUint8(i);
        final g = data.getUint8(i + 1);
        final b = data.getUint8(i + 2);
        final hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
        if (hsl.lightness < 0.08 || hsl.lightness > 0.94) continue;
        final gray = hsl.saturation < 0.12;
        final weight = 0.12 + (gray ? 0 : hsl.saturation * (1 - (hsl.lightness - 0.5).abs()));
        final bucket = gray ? hueBuckets : (hsl.hue / 360 * hueBuckets).floor() % hueBuckets;
        weights[bucket] += weight;
        reds[bucket] += r * weight;
        greens[bucket] += g * weight;
        blues[bucket] += b * weight;
      }
    }

    var best = -1;
    var bestWeight = 0.0;
    for (var i = 0; i < bucketCount; i++) {
      if (weights[i] > bestWeight) {
        bestWeight = weights[i];
        best = i;
      }
    }
    if (best < 0) return null;

    return Color.fromARGB(
      255,
      (reds[best] / bestWeight).round().clamp(0, 255),
      (greens[best] / bestWeight).round().clamp(0, 255),
      (blues[best] / bestWeight).round().clamp(0, 255),
    );
  }
}
