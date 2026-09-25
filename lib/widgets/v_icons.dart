import 'package:flutter/material.dart';

import '../theme/vinilo_theme.dart';

/// Íconos de trazo fino del rediseño. Los del prototipo usan sus mismos
/// trazados SVG (viewBox, grosor de línea y todo); los que el prototipo no
/// dibuja siguen el mismo estilo. ♥, ♡, ✓ y ↖ no existen en Archivo ni en
/// IBM Plex Mono: van siempre como ícono para que iOS no los pinte como
/// emoji.
enum VIcon {
  back,
  share,
  addToList,
  bell,
  search,
  close,
  settings,
  more,
  plus,
  check,
  list,
  ranking,
  heart,
  heartFilled,
  arrowUpLeft,
  pencil,
  trash,
  camera,
  image,
  drag,
  chevronRight,
  chevronDown,
  signOut,
  send,
}

/// Un ícono de `VIcon` a `size` px. El grosor del trazo escala con el
/// tamaño, como un SVG con `viewBox`: `strokeWidth` va en unidades del
/// viewBox (por defecto, el del prototipo).
class VIconView extends StatelessWidget {
  const VIconView(
    this.icon, {
    super.key,
    this.size = 18,
    this.color,
    this.strokeWidth,
  });

  final VIcon icon;
  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final ink = color ?? IconTheme.of(context).color ?? c.ink;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _IconPainter(
          _specs[icon]!,
          color: ink,
          knockout: c.bg,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _IconSpec {
  const _IconSpec(this.viewBox, this.stroke, this.shapes);

  final double viewBox;
  final double stroke;
  final List<_Shape> shapes;
}

sealed class _Shape {
  const _Shape();
}

/// Un trazado SVG (`d`), con trazo o relleno del color del ícono.
class _PathShape extends _Shape {
  const _PathShape(this.d, {this.fill = false});

  final String d;
  final bool fill;
}

/// Un círculo; `knockout` lo rellena con el color del fondo (los tiradores
/// del ícono de ajustes llevan `fill="#0f0e0d"` en el prototipo).
class _CircleShape extends _Shape {
  const _CircleShape(this.cx, this.cy, this.r, {this.fill = false, this.knockout = false});

  final double cx;
  final double cy;
  final double r;
  final bool fill;
  final bool knockout;
}

class _RectShape extends _Shape {
  const _RectShape(this.x, this.y, this.w, this.h);

  final double x;
  final double y;
  final double w;
  final double h;
}

/// Texto dentro del ícono (los números del ícono de ranking).
class _TextShape extends _Shape {
  const _TextShape(this.text, this.x, this.y, this.size);

  final String text;
  final double x;
  final double y;
  final double size;
}

const Map<VIcon, _IconSpec> _specs = {
  // Del prototipo.
  VIcon.back: _IconSpec(20, 1.6, [_PathShape('M12 4L6 10l6 6')]),
  VIcon.share: _IconSpec(20, 1.6, [_PathShape('M10 3v10M6 7l4-4 4 4M4 11v6h12v-6')]),
  VIcon.addToList: _IconSpec(20, 1.6, [_PathShape('M3 5h10M3 10h10M3 15h6M15 12v6M12 15h6')]),
  VIcon.bell: _IconSpec(20, 1.5, [
    _PathShape('M5 14V9a5 5 0 0110 0v5l1.5 2h-13z'),
    _PathShape('M8.5 18.5h3'),
  ]),
  VIcon.search: _IconSpec(20, 1.6, [
    _CircleShape(9, 9, 5.5),
    _PathShape('M13 13l4 4'),
  ]),
  VIcon.close: _IconSpec(20, 1.6, [_PathShape('M5 5l10 10M15 5L5 15')]),
  VIcon.settings: _IconSpec(20, 1.6, [
    _PathShape('M3 6h14M3 14h14'),
    _CircleShape(7, 6, 2, knockout: true),
    _CircleShape(13, 14, 2, knockout: true),
  ]),
  // Tres puntos de 3 px separados 3 px (el menú de listas).
  VIcon.more: _IconSpec(20, 1.6, [
    _CircleShape(4, 10, 1.5, fill: true),
    _CircleShape(10, 10, 1.5, fill: true),
    _CircleShape(16, 10, 1.5, fill: true),
  ]),
  VIcon.plus: _IconSpec(14, 1.5, [_PathShape('M7 1v12M1 7h12')]),
  VIcon.check: _IconSpec(10, 1.8, [_PathShape('M1.5 5.2l2.3 2.3L8.5 2.5')]),
  VIcon.list: _IconSpec(22, 1.5, [
    _PathShape('M8 5h12M8 11h12M8 17h12'),
    _RectShape(2, 4, 2, 2),
    _RectShape(2, 10, 2, 2),
    _RectShape(2, 16, 2, 2),
  ]),
  VIcon.ranking: _IconSpec(22, 1.5, [
    _PathShape('M9 5h11M9 11h11M9 17h11'),
    _TextShape('1', 1, 8, 7),
    _TextShape('2', 1, 14, 7),
    _TextShape('3', 1, 20, 7),
  ]),
  // Del mismo estilo, para lo que el prototipo escribe con símbolos o no
  // dibuja.
  VIcon.heart: _IconSpec(20, 1.6, [
    _PathShape(
      'M10 16.5C10 16.5 3.5 12.6 3.5 8.2C3.5 6 5.1 4.5 7 4.5C8.3 4.5 9.4 5.2 10 6.3'
      'C10.6 5.2 11.7 4.5 13 4.5C14.9 4.5 16.5 6 16.5 8.2C16.5 12.6 10 16.5 10 16.5Z',
    ),
  ]),
  VIcon.heartFilled: _IconSpec(20, 1.6, [
    _PathShape(
      'M10 16.5C10 16.5 3.5 12.6 3.5 8.2C3.5 6 5.1 4.5 7 4.5C8.3 4.5 9.4 5.2 10 6.3'
      'C10.6 5.2 11.7 4.5 13 4.5C14.9 4.5 16.5 6 16.5 8.2C16.5 12.6 10 16.5 10 16.5Z',
      fill: true,
    ),
  ]),
  VIcon.arrowUpLeft: _IconSpec(20, 1.6, [_PathShape('M15 15L5.5 5.5M5.5 12V5.5H12')]),
  VIcon.pencil: _IconSpec(20, 1.6, [_PathShape('M4 16l1-4 8.5-8.5 3 3L8 15l-4 1zM11.5 5.5l3 3')]),
  VIcon.trash: _IconSpec(20, 1.6, [_PathShape('M4 6h12M8 6V4h4v2M5.5 6l1 10h7l1-10')]),
  VIcon.camera: _IconSpec(20, 1.6, [
    _PathShape('M3 7h3l1.5-2h5L14 7h3v9H3z'),
    _CircleShape(10, 11, 3),
  ]),
  VIcon.image: _IconSpec(20, 1.6, [
    _PathShape('M3 4h14v12H3z'),
    _PathShape('M3 13l4-4 3 3 2-2 5 5'),
    _CircleShape(13, 7.5, 1.25),
  ]),
  VIcon.drag: _IconSpec(20, 1.6, [_PathShape('M4 7h12M4 10h12M4 13h12')]),
  VIcon.chevronRight: _IconSpec(20, 1.6, [_PathShape('M8 4l6 6-6 6')]),
  VIcon.chevronDown: _IconSpec(20, 1.6, [_PathShape('M4 8l6 6 6-6')]),
  VIcon.signOut: _IconSpec(20, 1.6, [_PathShape('M8 4H4v12h4M13 6l4 4-4 4M17 10H8')]),
  VIcon.send: _IconSpec(20, 1.6, [_PathShape('M4 10h12M11 5l5 5-5 5')]),
};

class _IconPainter extends CustomPainter {
  _IconPainter(
    this.spec, {
    required this.color,
    required this.knockout,
    this.strokeWidth,
  });

  final _IconSpec spec;
  final Color color;
  final Color knockout;
  final double? strokeWidth;

  static final Map<String, Path> _paths = {};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / spec.viewBox;
    canvas.save();
    canvas.scale(scale, scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth ?? spec.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final shape in spec.shapes) {
      switch (shape) {
        case _PathShape(:final d, fill: final filled):
          final path = _paths.putIfAbsent(d, () => _parseSvgPath(d));
          canvas.drawPath(path, filled ? fill : stroke);
        case _CircleShape(:final cx, :final cy, :final r, fill: final filled, :final knockout):
          final center = Offset(cx, cy);
          if (knockout) {
            canvas.drawCircle(center, r, Paint()..color = this.knockout);
            canvas.drawCircle(center, r, stroke);
          } else {
            canvas.drawCircle(center, r, filled ? fill : stroke);
          }
        case _RectShape(:final x, :final y, :final w, :final h):
          canvas.drawRect(Rect.fromLTWH(x, y, w, h), fill);
        case _TextShape(:final text, :final x, :final y, size: final fontSize):
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: VText.mono(fontSize, color: color, tracking: 0),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          // `y` es la línea base, como en SVG.
          final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          painter.paint(canvas, Offset(x, y - baseline));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.spec != spec ||
      old.color != color ||
      old.knockout != knockout ||
      old.strokeWidth != strokeWidth;
}

/// Lee un trazado SVG sencillo: M, L, H, V, C, A y Z (mayúsculas absolutas,
/// minúsculas relativas), con las banderas de los arcos pegadas como las
/// escribe el prototipo ("a5 5 0 0110 0").
Path _parseSvgPath(String d) {
  final path = Path();
  final reader = _PathReader(d);
  var current = Offset.zero;
  var start = Offset.zero;
  String? command;
  while (true) {
    reader.skipSeparators();
    if (reader.done) break;
    if (reader.atCommand) command = reader.readCommand();
    final cmd = command;
    if (cmd == null) break;
    final relative = cmd.toLowerCase() == cmd;
    Offset point(double x, double y) =>
        relative ? current + Offset(x, y) : Offset(x, y);
    switch (cmd.toUpperCase()) {
      case 'M':
        current = point(reader.number(), reader.number());
        start = current;
        path.moveTo(current.dx, current.dy);
        // Los pares siguientes a una M son líneas.
        command = relative ? 'l' : 'L';
      case 'L':
        current = point(reader.number(), reader.number());
        path.lineTo(current.dx, current.dy);
      case 'H':
        final x = reader.number();
        current = Offset(relative ? current.dx + x : x, current.dy);
        path.lineTo(current.dx, current.dy);
      case 'V':
        final y = reader.number();
        current = Offset(current.dx, relative ? current.dy + y : y);
        path.lineTo(current.dx, current.dy);
      case 'C':
        final c1 = point(reader.number(), reader.number());
        final c2 = point(reader.number(), reader.number());
        final end = point(reader.number(), reader.number());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        current = end;
      case 'A':
        final rx = reader.number();
        final ry = reader.number();
        final rotation = reader.number();
        final largeArc = reader.flag();
        final sweep = reader.flag();
        final end = point(reader.number(), reader.number());
        path.arcToPoint(
          end,
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
        current = end;
      case 'Z':
        path.close();
        current = start;
        command = null;
      default:
        return path;
    }
  }
  return path;
}

class _PathReader {
  _PathReader(this.source);

  final String source;
  int _i = 0;

  bool get done => _i >= source.length;

  bool get atCommand {
    final ch = source[_i];
    return RegExp(r'[MmLlHhVvCcAaZz]').hasMatch(ch);
  }

  String readCommand() => source[_i++];

  void skipSeparators() {
    while (!done && (source[_i] == ' ' || source[_i] == ',')) {
      _i++;
    }
  }

  double number() {
    skipSeparators();
    final match = RegExp(r'-?(\d+\.?\d*|\.\d+)').matchAsPrefix(source, _i);
    if (match == null) throw FormatException('Número esperado en "$source"', source, _i);
    _i = match.end;
    return double.parse(match.group(0)!);
  }

  bool flag() {
    skipSeparators();
    final ch = source[_i++];
    return ch == '1';
  }
}
