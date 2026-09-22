import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Una pestaña de la barra nativa: etiqueta y nombres de SF Symbols.
class NativeTab {
  const NativeTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final String icon;
  final String? selectedIcon;

  Map<String, Object?> toMap() => {
        'label': label,
        'icon': icon,
        'selectedIcon': selectedIcon,
      };
}

/// UITabBar de iOS incrustado como platform view (ver ios/Runner/NativeTabBar.swift).
/// Con el SDK de iOS 26 se dibuja con Liquid Glass. Solo tiene sentido en
/// iOS 26 o superior: consultar [NativeTabBar.isSupported] antes de usarlo.
///
/// Va pegado al borde inferior de la pantalla, sin SafeArea: el UITabBar
/// necesita cubrir la zona del indicador de inicio para colocar la píldora
/// donde la pone iOS. Encajonado más arriba, la aplasta y corta las etiquetas.
class NativeTabBar extends StatefulWidget {
  const NativeTabBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.tint,
    required this.unselectedTint,
    required this.dark,
  });

  final List<NativeTab> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final Color tint;
  final Color unselectedTint;
  final bool dark;

  /// True en iOS 26 o superior, donde UIKit trae Liquid Glass.
  static final bool isSupported = _detectSupport();

  static bool _detectSupport() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    final match = RegExp(r'Version (\d+)').firstMatch(Platform.operatingSystemVersion);
    final major = int.tryParse(match?.group(1) ?? '');
    return major != null && major >= 26;
  }

  @override
  State<NativeTabBar> createState() => _NativeTabBarState();
}

class _NativeTabBarState extends State<NativeTabBar> {
  MethodChannel? _channel;
  Rect? _hitRect;
  double? _height;

  Map<String, Object?> get _style => {
        'tint': widget.tint.toARGB32(),
        'unselectedTint': widget.unselectedTint.toARGB32(),
        'dark': widget.dark,
      };

  void _onCreated(int id) {
    final channel = MethodChannel('vinilo/tabbar_$id');
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'selected':
          widget.onSelected(call.arguments as int);
        case 'height':
          final h = (call.arguments as num).toDouble();
          if (mounted && h != _height) setState(() => _height = h);
        case 'frame':
          final v = (call.arguments as List).cast<num>();
          final rect = Rect.fromLTWH(
            v[0].toDouble(),
            v[1].toDouble(),
            v[2].toDouble(),
            v[3].toDouble(),
          ).inflate(6);
          if (mounted && rect != _hitRect) setState(() => _hitRect = rect);
      }
      return null;
    });
    _channel = channel;
  }

  @override
  void didUpdateWidget(NativeTabBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      _channel?.invokeMethod('setSelected', widget.selected);
    }
    if (old.tint != widget.tint ||
        old.unselectedTint != widget.unselectedTint ||
        old.dark != widget.dark) {
      _channel?.invokeMethod('setStyle', _style);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Hasta que UIKit informe su alto, el de un UITabBarController.
      height: _height ?? 49 + MediaQuery.viewPaddingOf(context).bottom,
      child: _HitRegion(
        rect: _hitRect,
        child: UiKitView(
          viewType: 'vinilo/tabbar',
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: {
            'items': widget.items.map((t) => t.toMap()).toList(),
            'selected': widget.selected,
            ..._style,
          },
          onPlatformViewCreated: _onCreated,
        ),
      ),
    );
  }
}

/// Deja pasar a Flutter los toques que caen fuera de la píldora de vidrio.
class _HitRegion extends SingleChildRenderObjectWidget {
  const _HitRegion({required this.rect, required super.child});

  final Rect? rect;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitRegion(rect);

  @override
  void updateRenderObject(BuildContext context, _RenderHitRegion renderObject) {
    renderObject.rect = rect;
  }
}

class _RenderHitRegion extends RenderProxyBox {
  _RenderHitRegion(this.rect);

  Rect? rect;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final r = rect;
    if (r != null && !r.contains(position)) return false;
    return super.hitTest(result, position: position);
  }
}
