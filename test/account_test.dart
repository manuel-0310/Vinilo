import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/services/account_service.dart';

void main() {
  group('AccountService.endpointFrom', () {
    test('la función de cuenta vive junto a la de Spotify', () {
      expect(
        AccountService.endpointFrom(
          override: '',
          spotifyUrl: 'https://us-central1-red-social-c786b.cloudfunctions.net/spotify',
        ).toString(),
        'https://us-central1-red-social-c786b.cloudfunctions.net/account',
      );
    });

    test('ACCOUNT_FN_URL manda si viene', () {
      expect(
        AccountService.endpointFrom(
          override: 'https://example.com/cuentas',
          spotifyUrl: 'https://x.net/spotify',
        ).toString(),
        'https://example.com/cuentas',
      );
    });

    test('sin URL o con una que no sabe traducir no inventa nada', () {
      expect(AccountService.endpointFrom(override: '', spotifyUrl: ''), isNull);
      expect(
        AccountService.endpointFrom(override: '', spotifyUrl: 'https://spotify-abc.a.run.app'),
        isNull,
      );
    });
  });
}
