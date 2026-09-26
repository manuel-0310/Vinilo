import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Color en OKLCH (luminosidad 0–1, croma y tonalidad en grados), el
/// espacio en el que el prototipo escribe sus colores. Sirve para convertir
/// la paleta y para sacar de una portada o del color de una persona sus
/// tonos derivados (ver `coverTone`, `coverShade`, `personTone`).
@immutable
class Oklch {
  const Oklch(this.l, this.c, this.h);

  /// Luminosidad percibida, de 0 (negro) a 1 (blanco).
  final double l;

  /// Croma: 0 es gris; los colores de la paleta van de 0,1 a 0,19.
  final double c;

  /// Tonalidad en grados (0–360).
  final double h;

  factory Oklch.fromColor(Color color) {
    final (lab, a, b) = _oklab(color);
    final chroma = math.sqrt(a * a + b * b);
    var hue = math.atan2(b, a) * 180 / math.pi;
    if (hue < 0) hue += 360;
    return Oklch(lab, chroma, hue);
  }

  /// El color en sRGB. Si queda fuera de la gama, baja el croma (sin tocar
  /// luminosidad ni tonalidad) hasta que entre, como hacen los navegadores.
  Color toColor({double opacity = 1}) {
    var rgb = _linearRgb(l, c, h);
    if (!_inGamut(rgb)) {
      var lo = 0.0;
      var hi = c;
      for (var i = 0; i < 24; i++) {
        final mid = (lo + hi) / 2;
        if (_inGamut(_linearRgb(l, mid, h))) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      rgb = _linearRgb(l, lo, h);
    }
    return Color.from(
      alpha: opacity,
      red: _encode(rgb.$1),
      green: _encode(rgb.$2),
      blue: _encode(rgb.$3),
    );
  }

  /// Distancia perceptual entre dos colores (euclídea en OKLab).
  static double distance(Color x, Color y) {
    final (l1, a1, b1) = _oklab(x);
    final (l2, a2, b2) = _oklab(y);
    final dl = l1 - l2;
    final da = a1 - a2;
    final db = b1 - b2;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  @override
  String toString() =>
      'oklch(${l.toStringAsFixed(3)} ${c.toStringAsFixed(3)} ${h.toStringAsFixed(1)})';
}

/// Tono claro de una portada: la misma tonalidad con luminosidad ≈ 0,76
/// (las portadas muy claras se quedan claras) y un croma moderado; los
/// grises siguen grises. Es el color de la nota grande y del artista en el
/// disco, de la regla de notas, del diario, de la discografía y de los
/// números del ranking. En el tema claro (`coverToneFor`) va oscuro, con
/// luminosidad ≈ 0,48, para leerse sobre el papel.
Color coverTone(Color cover) => coverToneFor(cover, Brightness.dark);

Color coverToneFor(Color cover, Brightness brightness) {
  final o = Oklch.fromColor(cover);
  final l = brightness == Brightness.dark
      ? o.l.clamp(0.76, 0.86).toDouble()
      : o.l.clamp(0.44, 0.52).toDouble();
  final c = o.c < 0.02 ? o.c * 2 : math.min(0.15, 0.6 * o.c + 0.05);
  return Oklch(l, c, o.h).toColor();
}

/// Tono oscuro de una portada o de un color: la franja de 300 px de las
/// listas (luminosidad 0,31) y el banner de un perfil sin foto (0,35). En
/// claro (`coverShadeFor`) es el mismo tono pero claro (1,17 − luminosidad:
/// 0,86 y 0,82), porque encima va la tinta oscura.
Color coverShade(Color color, {double lightness = 0.31}) =>
    coverShadeFor(color, Brightness.dark, lightness: lightness);

Color coverShadeFor(Color color, Brightness brightness, {double lightness = 0.31}) {
  if (brightness == Brightness.light) lightness = 1.17 - lightness;
  final o = Oklch.fromColor(color);
  final c = o.c < 0.02 ? o.c : (0.6 * o.c + 0.01).clamp(0.02, 0.08).toDouble();
  return Oklch(lightness, c, o.h).toColor();
}

/// Fondo del avatar de una persona sin foto: su color, apagado (claro en el
/// tema claro, porque la inicial va en tinta).
Color personTone(Color color) => personToneFor(color, Brightness.dark);

Color personToneFor(Color color, Brightness brightness) {
  final o = Oklch.fromColor(color);
  final l = brightness == Brightness.dark ? 0.44 : 0.82;
  return Oklch(l, math.min(o.c, brightness == Brightness.dark ? 0.12 : 0.08), o.h).toColor();
}

(double, double, double) _oklab(Color color) {
  final r = _decode(color.r);
  final g = _decode(color.g);
  final b = _decode(color.b);
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

(double, double, double) _linearRgb(double lightness, double chroma, double hue) {
  final rad = hue * math.pi / 180;
  final a = chroma * math.cos(rad);
  final b = chroma * math.sin(rad);
  final l = math.pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3).toDouble();
  final m = math.pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3).toDouble();
  final s = math.pow(lightness - 0.0894841775 * a - 1.2914855480 * b, 3).toDouble();
  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  );
}

bool _inGamut((double, double, double) rgb) {
  const eps = 1e-4;
  bool ok(double v) => v >= -eps && v <= 1 + eps;
  return ok(rgb.$1) && ok(rgb.$2) && ok(rgb.$3);
}

double _decode(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _encode(double v) {
  final x = v.clamp(0.0, 1.0);
  return x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
}

double _cbrt(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();
