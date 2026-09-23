import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../theme/vinilo_theme.dart';

/// Abre el recortador a pantalla completa y devuelve la imagen ya recortada,
/// redimensionada a `outputWidth` de ancho y codificada en JPEG. Null si la
/// persona cancela. `circle` solo cambia la máscara que se ve: la imagen que
/// se exporta es el cuadrado que la contiene (así el JPEG no necesita alfa).
Future<Uint8List?> showImageCropper(
  BuildContext context, {
  required Uint8List bytes,
  required double aspectRatio,
  required int outputWidth,
  bool circle = false,
  String title = 'Ajusta tu foto',
}) {
  return Navigator.of(context).push<Uint8List>(
    PageRouteBuilder(
      opaque: true,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => ImageCropper(
        bytes: bytes,
        aspectRatio: aspectRatio,
        outputWidth: outputWidth,
        circle: circle,
        title: title,
      ),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  );
}

/// Mover, hacer zoom y recortar una imagen dentro de un marco fijo.
/// Todo en Dart: la imagen la decodifica Flutter, el recorte se pinta en un
/// lienzo y el JPEG lo escribe el paquete `image` en un isolate aparte.
class ImageCropper extends StatefulWidget {
  const ImageCropper({
    super.key,
    required this.bytes,
    required this.aspectRatio,
    required this.outputWidth,
    this.circle = false,
    this.title = 'Ajusta tu foto',
    this.quality = 85,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final int outputWidth;
  final bool circle;
  final String title;
  final int quality;

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  ui.Image? _image;
  Object? _error;
  bool _exporting = false;

  /// Píxeles de la imagen → puntos del marco.
  double _scale = 1;

  /// Esquina superior izquierda de la imagen, en coordenadas del marco.
  Offset _offset = Offset.zero;
  Size _frame = Size.zero;

  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final image = await decodeImageFromList(widget.bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  double get _minScale {
    final image = _image;
    if (image == null || _frame.isEmpty) return 1;
    return math.max(_frame.width / image.width, _frame.height / image.height);
  }

  /// Coloca la imagen cubriendo el marco y centrada (estado inicial o cuando
  /// cambia el tamaño del marco).
  void _fit(Size frame) {
    final image = _image!;
    _frame = frame;
    _scale = _minScale;
    _offset = Offset(
      (frame.width - image.width * _scale) / 2,
      (frame.height - image.height * _scale) / 2,
    );
  }

  Offset _clamp(Offset offset, double scale) {
    final image = _image!;
    final w = image.width * scale;
    final h = image.height * scale;
    return Offset(
      offset.dx.clamp(_frame.width - w, 0.0),
      offset.dy.clamp(_frame.height - h, 0.0),
    );
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final minScale = _minScale;
    final scale = (_startScale * d.scale).clamp(minScale, minScale * 8);
    // El punto de la imagen bajo los dedos se queda bajo los dedos.
    final anchor = (_startFocal - _startOffset) / _startScale;
    final offset = d.localFocalPoint - anchor * scale;
    setState(() {
      _scale = scale;
      _offset = _clamp(offset, scale);
    });
  }

  void _onDoubleTap() {
    setState(() => _fit(_frame));
  }

  Future<void> _export() async {
    final image = _image;
    if (image == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final outW = widget.outputWidth;
      final outH = (outW / widget.aspectRatio).round();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Escala por eje: si el marco tiene decimales, un solo factor dejaba
      // una franja sin cubrir en el borde de la foto final.
      canvas.scale(outW / _frame.width, outH / _frame.height);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(_offset.dx, _offset.dy, image.width * _scale, image.height * _scale),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final out = await picture.toImage(outW, outH);
      picture.dispose();
      final rgba = await out.toByteData(format: ui.ImageByteFormat.rawRgba);
      out.dispose();
      if (rgba == null) throw StateError('No se pudo leer la imagen recortada');
      final jpeg = await compute(
        _encodeJpeg,
        _EncodeJob(rgba.buffer.asUint8List(), outW, outH, widget.quality),
      );
      if (mounted) Navigator.of(context).pop(jpeg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo recortar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final image = _image;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    // Sobre el fondo oscuro del recortador el texto siempre va claro.
    const ink = Color(0xFFF4EFE6);
    const ink2 = Color(0xFFA9A296);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0A09),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 18, VSpace.page, 0),
            child: Column(
              children: [
                Text(widget.title, style: VText.display(30, color: ink, height: 1)),
                const SizedBox(height: 6),
                Text(
                  'Mueve y haz zoom con dos dedos. Doble toque para reiniciar.',
                  textAlign: TextAlign.center,
                  style: VText.ui(13, color: ink2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
              child: Center(
                child: image == null
                    ? (_error != null
                        ? Text('No se pudo abrir la imagen: $_error',
                            style: VText.ui(14, color: ink2))
                        : const CircularProgressIndicator(color: ink2))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          var frameW = constraints.maxWidth;
                          var frameH = frameW / widget.aspectRatio;
                          if (frameH > constraints.maxHeight) {
                            frameH = constraints.maxHeight;
                            frameW = frameH * widget.aspectRatio;
                          }
                          final frame = Size(frameW, frameH);
                          if (frame != _frame) _fit(frame);
                          return GestureDetector(
                            key: const ValueKey('crop-canvas'),
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _onScaleStart,
                            onScaleUpdate: _onScaleUpdate,
                            onDoubleTap: _onDoubleTap,
                            child: ClipRect(
                              child: CustomPaint(
                                size: frame,
                                painter: _CropPainter(
                                  image: image,
                                  scale: _scale,
                                  offset: _offset,
                                  circle: widget.circle,
                                  frameColor: c.accent,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, bottomPad + 18),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const ValueKey('crop-cancel'),
                    onPressed: _exporting ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: ink,
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text('Cancelar', style: VText.ui(16, weight: 700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: const ValueKey('crop-confirm'),
                    onPressed: image == null || _exporting ? null : _export,
                    child: _exporting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent),
                          )
                        : const Text('Usar foto'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.image,
    required this.scale,
    required this.offset,
    required this.circle,
    required this.frameColor,
  });

  final ui.Image image;
  final double scale;
  final Offset offset;
  final bool circle;
  final Color frameColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offset.dx, offset.dy, image.width * scale, image.height * scale),
      Paint()..filterQuality = FilterQuality.medium,
    );
    if (circle) {
      // Velo fuera del círculo y un borde fino que marca el recorte.
      final hole = Path()..addOval(rect);
      final veil = Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        hole,
      );
      canvas.drawPath(veil, Paint()..color = Colors.black.withValues(alpha: 0.62));
      canvas.drawOval(
        rect.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.75),
      );
    } else {
      final rrect = RRect.fromRectAndRadius(rect.deflate(0.75), const Radius.circular(18));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.75),
      );
      // Guías de tercios, muy sutiles.
      final guide = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1;
      for (var i = 1; i < 3; i++) {
        final x = size.width * i / 3;
        final y = size.height * i / 3;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), guide);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.image != image ||
      old.scale != scale ||
      old.offset != offset ||
      old.circle != circle ||
      old.frameColor != frameColor;
}

class _EncodeJob {
  const _EncodeJob(this.rgba, this.width, this.height, this.quality);

  final Uint8List rgba;
  final int width;
  final int height;
  final int quality;
}

Uint8List _encodeJpeg(_EncodeJob job) {
  final image = img.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return img.encodeJpg(image, quality: job.quality);
}
