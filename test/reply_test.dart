import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/notification.dart';
import 'package:no_retiene/models/reply.dart';

PersonInfo person(String uid, String? username) =>
    PersonInfo(uid: uid, name: 'Nombre $uid', colorValue: 0xFF5FA8D3, username: username);

void main() {
  group('replyPrefix', () {
    test('empieza con el @ y un espacio', () {
      expect(replyPrefix(person('a', 'ana.m')), '@ana.m ');
    });

    test('sin @usuario no agrega nada', () {
      expect(replyPrefix(person('a', null)), '');
      expect(replyPrefix(person('a', '')), '');
    });
  });

  group('splitMentions', () {
    test('separa texto y menciones', () {
      final pieces = splitMentions('Hola @ana, mira esto @santi_m');
      expect(pieces.map((p) => p.text).join(), 'Hola @ana, mira esto @santi_m');
      expect(pieces.where((p) => p.handle != null).map((p) => p.handle), ['ana', 'santi_m']);
    });

    test('un punto final no es parte del @usuario', () {
      final pieces = splitMentions('Gracias @vale.rios.');
      expect(pieces.firstWhere((p) => p.handle != null).text, '@vale.rios');
      expect(pieces.last.text, '.');
    });

    test('un correo no es una mención', () {
      expect(splitMentions('escríbeme a ana@gmail.com').any((p) => p.handle != null), isFalse);
    });

    test('los @ muy cortos no cuentan', () {
      expect(splitMentions('@ab hola').any((p) => p.handle != null), isFalse);
    });

    test('las menciones se comparan en minúsculas', () {
      expect(splitMentions('@Ana.M').single.handle, 'ana.m');
    });

    test('texto sin menciones queda igual', () {
      expect(splitMentions('Solo texto'), [(text: 'Solo texto', handle: null)]);
    });
  });

  group('mentionsIn', () {
    final ana = person('uidAna', 'ana');
    final anabel = person('uidAnabel', 'anabel');
    final sin = person('uidSin', null);

    test('solo cuenta a quien sigue mencionada', () {
      expect(mentionsIn('@ana tienes razón', [ana, anabel]), ['uidAna']);
    });

    test('"@ana" no cuenta dentro de "@anabel"', () {
      expect(mentionsIn('@anabel sí', [ana, anabel]), ['uidAnabel']);
    });

    test('si se borró la mención, no se avisa', () {
      expect(mentionsIn('tienes razón', [ana]), isEmpty);
    });

    test('ignora a quien no tiene @usuario', () {
      expect(mentionsIn('@ana y @x', [sin, ana]), ['uidAna']);
    });
  });

  group('replyNotificationTargets', () {
    test('avisa a la dueña de la nota', () {
      expect(
        replyNotificationTargets(from: 'yo', ratingUid: 'duena', mentions: const []),
        [(to: 'duena', type: NotificationType.reply)],
      );
    });

    test('nunca a quien escribe', () {
      expect(
        replyNotificationTargets(from: 'duena', ratingUid: 'duena', mentions: const ['duena']),
        isEmpty,
      );
    });

    test('la dueña mencionada recibe un solo aviso', () {
      expect(
        replyNotificationTargets(from: 'yo', ratingUid: 'duena', mentions: const ['duena']),
        [(to: 'duena', type: NotificationType.reply)],
      );
    });

    test('las demás personas mencionadas reciben "te respondió", sin repetir', () {
      expect(
        replyNotificationTargets(
          from: 'yo',
          ratingUid: 'duena',
          mentions: const ['ana', 'ana', 'yo', 'beto'],
        ),
        [
          (to: 'duena', type: NotificationType.reply),
          (to: 'ana', type: NotificationType.mention),
          (to: 'beto', type: NotificationType.mention),
        ],
      );
    });

    test('la dueña que responde a alguien solo le avisa a esa persona', () {
      expect(
        replyNotificationTargets(from: 'duena', ratingUid: 'duena', mentions: const ['ana']),
        [(to: 'ana', type: NotificationType.mention)],
      );
    });
  });

  group('replySnippet', () {
    test('deja los textos cortos igual, sin espacios de sobra', () {
      expect(replySnippet('  hola\n\nqué tal  '), 'hola qué tal');
    });

    test('corta los largos con puntos suspensivos', () {
      final long = 'a' * 200;
      final snippet = replySnippet(long, max: 80);
      expect(snippet.length, 80);
      expect(snippet.endsWith('…'), isTrue);
    });
  });

  test('puede borrar la autora o la dueña de la nota', () {
    final reply = Reply(
      id: 'r1',
      ratingId: 'duena_disco',
      ratingUid: 'duena',
      uid: 'ana',
      user: person('ana', 'ana'),
      text: 'hola',
      createdAt: DateTime(2026),
    );
    expect(reply.canDelete('ana'), isTrue);
    expect(reply.canDelete('duena'), isTrue);
    expect(reply.canDelete('otra'), isFalse);
  });
}
