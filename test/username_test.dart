import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/util/auth_errors.dart';
import 'package:no_retiene/util/username.dart';

void main() {
  group('normalizeUsername', () {
    test('quita espacios, la arroba inicial y pasa a minúsculas', () {
      expect(normalizeUsername('  @Manuel.C  '), 'manuel.c');
      expect(normalizeUsername('LOLA_99'), 'lola_99');
      expect(normalizeUsername('@'), '');
    });

    test('solo quita una arroba y solo al principio', () {
      expect(normalizeUsername('@@ana'), '@ana');
      expect(normalizeUsername('an@a'), 'an@a');
    });
  });

  group('usernameProblem', () {
    test('acepta letras, números, punto y guion bajo de 3 a 20', () {
      for (final ok in ['ana', 'manuel.castillo', 'lola_99', '123', 'a.b_c',
          'abcdefghijklmnopqrst']) {
        expect(usernameProblem(ok), isNull, reason: ok);
        expect(isValidUsername(ok), isTrue, reason: ok);
      }
    });

    test('rechaza vacío, corto y largo', () {
      expect(usernameProblem(''), UsernameProblem.empty);
      expect(usernameProblem('ab'), UsernameProblem.tooShort);
      expect(usernameProblem('abcdefghijklmnopqrstu'), UsernameProblem.tooLong);
    });

    test('rechaza mayúsculas, espacios, tildes, guiones y arrobas', () {
      for (final bad in ['Ana', 'ana lopez', 'josé', 'ana-lopez', '@ana',
          'ana!', 'año']) {
        expect(usernameProblem(bad), UsernameProblem.badChars, reason: bad);
      }
    });

    test('los caracteres inválidos pesan más que la longitud', () {
      expect(usernameProblem('A'), UsernameProblem.badChars);
    });

    test('cada problema tiene un mensaje', () {
      for (final p in UsernameProblem.values) {
        expect(usernameProblemMessage(p), isNotEmpty);
      }
    });
  });

  group('stripUsername', () {
    test('deja solo lo permitido, en minúsculas', () {
      expect(stripUsername('@Manuel Castillo!'), 'manuelcastillo');
      expect(stripUsername('José.99_'), 'jos.99_');
      expect(stripUsername('   '), '');
    });

    test('lo que sale del formateador siempre pasa la validación de caracteres', () {
      for (final raw in ['Ana López', 'x@y.z', 'ÁÉÍ', 'a b c d e']) {
        final s = stripUsername(raw);
        expect(usernameProblem(s), isNot(UsernameProblem.badChars), reason: raw);
      }
    });
  });

  group('authMessageForCode', () {
    test('traduce los errores comunes', () {
      expect(authMessageForCode('email-already-in-use'), contains('ya tiene una cuenta'));
      expect(authMessageForCode('weak-password'), contains('6 caracteres'));
      expect(authMessageForCode('network-request-failed'), contains('conexión'));
      expect(authMessageForCode('invalid-email'), contains('correo'));
    });

    test('correo inexistente y contraseña mal dan el mismo mensaje', () {
      final wrong = authMessageForCode('wrong-password');
      expect(authMessageForCode('user-not-found'), wrong);
      expect(authMessageForCode('invalid-credential'), wrong);
    });

    test('un código desconocido cae al mensaje genérico', () {
      expect(authMessageForCode('lo-que-sea'), genericAuthMessage);
    });
  });
}
