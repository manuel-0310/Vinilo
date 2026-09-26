import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/palette.dart';
import '../services/services.dart';
import '../services/share_image.dart';
import '../services/share_service.dart';
import '../share_cards/share_card_data.dart';
import '../theme/vinilo_theme.dart';
import '../util/share_links.dart';
import 'share_button.dart';
import 'sheet.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// Una tarjeta que se puede compartir desde la hoja: cómo se dibuja en
/// cada formato, si tiene cuadrado, qué imágenes precargar y de qué portada
/// sacar el tono (el color dominante llega a `build`).
class ShareCardSpec {
  const ShareCardSpec({
    required this.build,
    this.square = false,
    this.images = const [],
    this.toneUrl,
  });

  final Widget Function(ShareCardFormat format, Color? coverColor) build;
  final bool square;
  final List<String?> images;
  final String? toneUrl;
}

/// Comparte desde un botón: con tarjetas (y en el teléfono) abre la hoja
/// "Compartir"; sin ellas, o en la web, lo de siempre (texto y enlace).
Future<void> openShare(
  BuildContext context, {
  required List<ShareCardSpec> cards,
  required ShareMessage Function(AppLocalizations l) message,
}) async {
  if (cards.isEmpty || !ShareService.canShareImages) {
    return shareMessage(context, message(context.l10n));
  }
  HapticFeedback.selectionClick();
  await showVSheet<void>(context, (_) => ShareSheet(cards: cards, message: message));
}

/// Hoja "Compartir" (prototipo "Hoja de compartir"): título, pestañas
/// Historia | Cuadrado, la vista previa a 0,6 (se desliza de lado si hay dos
/// tarjetas), 4 destinos y el botón de énfasis.
class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.cards, required this.message});

  final List<ShareCardSpec> cards;
  final ShareMessage Function(AppLocalizations l) message;

  /// Escala de la vista previa en el prototipo (216×384).
  static const double previewScale = 0.6;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  var _format = ShareCardFormat.story;
  var _page = 0;
  bool _busy = false;
  String? _notice;
  bool _noticeError = false;
  Timer? _noticeTimer;
  Future<void>? _ready;
  final Map<int, Color?> _tones = {};
  final Map<(int, ShareCardFormat), GlobalKey> _keys = {};
  final _pages = PageController();

  ShareCardSpec get _card => widget.cards[_page];
  bool get _hasSquare => _card.square;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ready ??= _prepare();
  }

  /// Espera las portadas y los tonos antes de mostrar (y capturar) nada.
  Future<void> _prepare() async {
    // Sin servicios (pruebas) saca los tonos con un servicio propio.
    final palette = context.getInheritedWidgetOfExactType<ServicesScope>()?.services.palette ?? PaletteService();
    await Future.wait([
      ShareImage.precache(context, [for (final c in widget.cards) ...c.images]),
      for (final (i, c) in widget.cards.indexed)
        palette.dominant(c.toneUrl).then((color) => _tones[i] = color),
    ]);
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int page, ShareCardFormat format) => _keys.putIfAbsent((page, format), GlobalKey.new);

  void _say(String text, {bool error = false}) {
    _noticeTimer?.cancel();
    setState(() {
      _notice = text;
      _noticeError = error;
    });
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  /// El PNG de la tarjeta visible en `format` (cambia de pestaña si hace
  /// falta, para que esté montada).
  Future<Uint8List> _png(ShareCardFormat format) async {
    await _ready;
    if (_format != format) {
      setState(() => _format = format);
      await WidgetsBinding.instance.endOfFrame;
    }
    return ShareImage.capture(_keyFor(_page, format));
  }

  Future<void> _run(Future<void> Function(AppLocalizations l) action) async {
    if (_busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action(l);
    } on ShareImageException catch (e) {
      _say(
        switch (e.error) {
          ShareImageError.denied => l.shareSaveDenied,
          ShareImageError.unsupported => l.shareImageUnsupported,
          ShareImageError.failed => l.shareImageFailed,
        },
        error: true,
      );
    } catch (_) {
      _say(l.shareImageFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stories() => _run((l) async {
        final png = await _png(ShareCardFormat.story);
        if (await ShareService.instagramStory(png)) return;
        final m = widget.message(l);
        await ShareService.shareImage(png, m.text, m.url);
      });

  Future<void> _image() => _run((l) async {
        final png = await _png(_format);
        final m = widget.message(l);
        await ShareService.shareImage(png, m.text, m.url);
      });

  Future<void> _save() => _run((l) async {
        final png = await _png(_format);
        await ShareService.saveImage(png);
        HapticFeedback.lightImpact();
        _say(l.shareImageSaved);
      });

  Future<void> _link() => shareMessage(context, widget.message(context.l10n));

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final screen = MediaQuery.sizeOf(context).height;
    final story = _format == ShareCardFormat.story;
    return SheetScaffold(
      key: const ValueKey('share-sheet'),
      title: l.shareAction,
      titleSize: 40,
      // Empieza a 96 del borde de arriba, como en el prototipo.
      height: math.max(0.5, (screen - 96) / screen),
      scrollable: false,
      trailing: _hasSquare ? _Tabs(format: _format, onChanged: (f) => setState(() => _format = f)) : null,
      footer: VPrimaryButton.accent(
        key: const ValueKey('share-primary'),
        label: story ? l.shareToStories : l.shareImage,
        busy: _busy,
        onPressed: story ? _stories : _image,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _ready,
              builder: (context, snap) => _preview(context, ready: snap.connectionState == ConnectionState.done),
            ),
          ),
          if (widget.cards.length > 1 && story) ...[
            _Dots(count: widget.cards.length, selected: _page),
            const SizedBox(height: 16),
          ],
          // Aviso de lo que pasó: "Imagen guardada" en mono, o el error en
          // una frase (hasta dos líneas).
          SizedBox(
            height: 34,
            child: _notice == null
                ? null
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    child: Center(
                      key: const ValueKey('share-notice'),
                      child: _noticeError
                          ? Text(
                              _notice!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: VText.ui(12.5, color: c.danger, height: 1.3),
                            )
                          : VMono(_notice!, size: 10, color: c.accentText, maxLines: 1),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Target(keyName: 'share-target-story', icon: VIcon.story, label: l.shareTargetStories, onTap: _busy ? null : _stories),
                const SizedBox(width: 8),
                _Target(keyName: 'share-target-whatsapp', icon: VIcon.chat, label: l.shareTargetWhatsapp, onTap: _busy ? null : _image),
                const SizedBox(width: 8),
                _Target(keyName: 'share-target-save', icon: VIcon.download, label: l.shareTargetSave, onTap: _busy ? null : _save),
                const SizedBox(width: 8),
                _Target(keyName: 'share-target-link', icon: VIcon.link, label: l.shareTargetLink, onTap: _link),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context, {required bool ready}) {
    final c = VColors.of(context);
    return LayoutBuilder(builder: (context, box) {
      final size = _format.size;
      // A 0,6 como el prototipo, o menos si la pantalla es baja.
      final scale = math.max(0.3, math.min(ShareSheet.previewScale, (box.maxHeight - 40) / size.height));
      final shown = size * scale;
      Widget framed(int page) {
        final spec = widget.cards[page];
        return Center(
          child: Container(
            width: shown.width,
            height: shown.height,
            foregroundDecoration: BoxDecoration(border: Border.all(color: c.line)),
            color: c.surface,
            child: !ready
                ? null
                : FittedBox(
                    // La tarjeta se dibuja a su tamaño completo dentro del
                    // RepaintBoundary (así se captura a 1080 de ancho) y se
                    // escala por fuera.
                    child: RepaintBoundary(
                      key: _keyFor(page, _format),
                      child: spec.build(_format, _tones[page]),
                    ),
                  ),
          ),
        );
      }

      if (widget.cards.length == 1 || _format != ShareCardFormat.story) {
        return KeyedSubtree(key: const ValueKey('share-preview'), child: framed(_page));
      }
      return PageView.builder(
        key: const ValueKey('share-preview'),
        controller: _pages,
        itemCount: widget.cards.length,
        onPageChanged: (i) => setState(() {
          _page = i;
          if (!widget.cards[i].square) _format = ShareCardFormat.story;
        }),
        itemBuilder: (context, i) => framed(i),
      );
    });
  }
}

/// "Historia | Cuadrado": 14, la elegida en 600 con la raya de énfasis de 2.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.format, required this.onChanged});

  final ShareCardFormat format;
  final ValueChanged<ShareCardFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    Widget tab(ShareCardFormat f, String label, String key) {
      final selected = f == format;
      return GestureDetector(
        key: ValueKey(key),
        behavior: HitTestBehavior.opaque,
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged(f);
              },
        child: Container(
          padding: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? c.accent : Colors.transparent, width: 2)),
          ),
          child: Text(
            label,
            style: VText.ui(14, weight: selected ? 600 : 500, color: selected ? c.ink : c.inactive),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tab(ShareCardFormat.story, l.shareTabStory, 'share-tab-story'),
        const SizedBox(width: 18),
        tab(ShareCardFormat.square, l.shareTabSquare, 'share-tab-square'),
      ],
    );
  }
}

/// Un destino: caja de 56 con borde `lineStrong`, ícono de 22 y etiqueta
/// mono de 9,5.
class _Target extends StatelessWidget {
  const _Target({required this.keyName, required this.icon, required this.label, required this.onTap});

  final String keyName;
  final VIcon icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Expanded(
      child: Pressable(
        key: ValueKey(keyName),
        onTap: onTap,
        builder: (context, pressed) => Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: pressed ? c.ink : c.lineStrong),
              ),
              child: VIconView(icon, size: 22, color: onTap == null ? c.ink4 : c.ink),
            ),
            const SizedBox(height: 8),
            VMono(label, size: 9.5, tracking: 0.06, color: c.ink2, align: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

/// Dos puntos cuadrados bajo la vista previa cuando hay dos tarjetas.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.selected});

  final int count;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(width: 6, height: 6, color: i == selected ? c.ink : c.inkA(0.3)),
        ],
      ],
    );
  }
}
