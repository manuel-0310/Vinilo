import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/services/web_service.dart';
import 'package:no_retiene/util/function_url.dart';

void main() {
  group('siblingFunctionUrl', () {
    test('la función web vive junto a la de Spotify', () {
      expect(
        siblingFunctionUrl('https://us-central1-red-social-c786b.cloudfunctions.net/spotify', 'web')
            .toString(),
        'https://us-central1-red-social-c786b.cloudfunctions.net/web',
      );
    });

    test('sin URL o con otra forma no inventa nada', () {
      expect(siblingFunctionUrl('', 'web'), isNull);
      expect(siblingFunctionUrl('https://spotify-abc.a.run.app', 'web'), isNull);
    });
  });

  group('WebService.parseCovers', () {
    test('toma las URLs https, hasta 8', () {
      final urls = List.generate(10, (i) => '"https://i.scdn.co/image/$i"').join(',');
      final covers = WebService.parseCovers('{"covers":[$urls]}');
      expect(covers, hasLength(8));
      expect(covers.first, 'https://i.scdn.co/image/0');
    });

    test('descarta lo que no es una URL segura', () {
      expect(
        WebService.parseCovers('{"covers":["http://x.test/a.jpg", 3, "https://i.scdn.co/image/b"]}'),
        ['https://i.scdn.co/image/b'],
      );
    });

    test('una respuesta rota da la lista vacía', () {
      expect(WebService.parseCovers('<html>'), isEmpty);
      expect(WebService.parseCovers('{"covers":null}'), isEmpty);
      expect(WebService.parseCovers('[]'), isEmpty);
    });
  });
}
