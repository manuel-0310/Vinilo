import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/services/palette.dart';
import 'package:no_retiene/theme/oklch.dart';
import 'package:no_retiene/theme/vinilo_theme.dart';
import 'package:no_retiene/widgets/v_ruler.dart';

/// Una imagen RGBA de `width`×`height` donde cada píxel lo decide `color`.
ByteData image(int width, int height, Color Function(int x, int y) color) {
  final bytes = ByteData(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final c = color(x, y);
      final i = (y * width + x) * 4;
      bytes.setUint8(i, (c.r * 255).round());
      bytes.setUint8(i + 1, (c.g * 255).round());
      bytes.setUint8(i + 2, (c.b * 255).round());
      bytes.setUint8(i + 3, 255);
    }
  }
  return bytes;
}

void main() {
  group('color de la portada (PaletteService.pick)', () {
    test('devuelve el color tal cual, sin aclararlo ni saturarlo', () {
      const blue = Color(0xFF1B3A6B);
      final picked = PaletteService.pick(image(20, 20, (_, _) => blue), 20, 20)!;
      expect(picked.toARGB32(), blue.toARGB32());
    });

    test('una portada gris da un gris, y su tono sigue gris', () {
      const gray = Color(0xFF8A8A8A);
      final picked = PaletteService.pick(image(20, 20, (_, _) => gray), 20, 20)!;
      expect(Oklch.fromColor(picked).c, lessThan(0.02));
      expect(Oklch.fromColor(coverTone(picked)).c, lessThan(0.04));
    });

    test('los grises no se mezclan con los rojos', () {
      // Mitad gris, mitad rojo: gana el rojo (más saturado), y sin gris
      // mezclado.
      const gray = Color(0xFF808080);
      const red = Color(0xFFC0302A);
      final picked = PaletteService.pick(image(20, 20, (x, _) => x < 10 ? gray : red), 20, 20)!;
      expect(picked.toARGB32(), red.toARGB32());
    });

    test('sin píxeles útiles (todo negro), null', () {
      final picked = PaletteService.pick(image(10, 10, (_, _) => const Color(0xFF000000)), 10, 10);
      expect(picked, isNull);
    });
  });

  testWidgets('regla del disco: antes de la nota en tinta, después apagados', (tester) async {
    const after = Color(0x80EFEBE4);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildViniloTheme(ViniloPalette.dark),
        home: const Scaffold(
          body: RulerCells(selected: 6, afterNumberColor: after, fill: Color(0xFF1B3A6B)),
        ),
      ),
    );
    Color colorOf(int k) => tester.widget<Text>(find.text('$k')).style!.color!;
    expect(colorOf(3), ViniloPalette.dark.ink);
    expect(colorOf(6), ViniloPalette.dark.onAccent);
    expect(colorOf(7), after);
    expect(colorOf(10), after);
  });
}
