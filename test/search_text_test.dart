import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/util/search_text.dart';

void main() {
  group('foldForSearch', () {
    test('quita tildes, diéresis y mayúsculas', () {
      expect(foldForSearch('Café Tacvba'), 'cafe tacvba');
      expect(foldForSearch('MÜNCHEN'), 'munchen');
      expect(foldForSearch('Él Mató a un Policía Motorizado'),
          'el mato a un policia motorizado');
    });

    test('también quita acentos que llegan como carácter aparte', () {
      expect(foldForSearch('Cafe\u0301'), 'cafe');
    });

    test('la ñ cuenta como n', () {
      expect(foldForSearch('Año'), 'ano');
    });

    test('recorta y junta los espacios de sobra', () {
      expect(foldForSearch('  ok    computer '), 'ok computer');
    });
  });

  group('albumMatches', () {
    const album = Album(id: '1', name: 'Re', artist: 'Café Tacvba');

    test('coincide por el artista aunque se escriba sin tilde', () {
      expect(albumMatches(album, 'cafe'), isTrue);
      expect(albumMatches(album, 'TACV'), isTrue);
    });

    test('coincide por el nombre del disco', () {
      expect(albumMatches(album, 're'), isTrue);
    });

    test('no coincide si no aparece', () {
      expect(albumMatches(album, 'radiohead'), isFalse);
    });

    test('sin texto coincide todo', () {
      expect(albumMatches(album, '   '), isTrue);
    });
  });
}
