import 'dart:math' as math;
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/moderation.dart';
import 'package:no_retiene/models/notification.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/reply.dart';
import 'package:no_retiene/services/moderation_repo.dart';
import 'package:no_retiene/util/format.dart';
import 'package:no_retiene/util/offensive.dart';

PersonInfo _person(String uid) => PersonInfo(uid: uid, name: uid, colorValue: 0xFF000000);

RatingEntry _rating(String uid, String album) => RatingEntry(
      id: RatingEntry.docId(uid, album),
      uid: uid,
      albumId: album,
      score: 8,
      note: '',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
      album: Album(id: album, name: album, artist: 'x'),
      user: RaterInfo(uid: uid, name: uid, colorValue: 0xFF000000),
    );

Reply _reply(String id, String uid) => Reply(
      id: id,
      ratingId: 'r',
      ratingUid: 'owner',
      uid: uid,
      user: _person(uid),
      text: 'hola',
      createdAt: DateTime(2026, 9, 1),
    );

AppNotification _notification(String from) => AppNotification(
      id: 'n-$from',
      to: 'me',
      from: _person(from),
      type: NotificationType.follow,
      createdAt: DateTime(2026, 9, 1),
      read: false,
    );

BlockEdge _edge(String blocked) => BlockEdge(
      blocker: 'me',
      blocked: blocked,
      blockedInfo: _person(blocked),
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  group('ModerationState', () {
    final state = ModerationState(
      blocked: {'ana': _edge('ana')},
      blockedBy: const {'beto'},
      muted: {'caro': MutedPerson(info: _person('caro'), createdAt: DateTime(2026, 9, 1))},
      hidden: {RatingEntry.docId('dani', 'a2'), 'reply-2'},
    );

    test('el bloqueo vale en los dos sentidos', () {
      expect(state.isBlocked('ana'), isTrue);
      expect(state.blocksMe('beto'), isTrue);
      expect(state.hidesUser('ana'), isTrue);
      expect(state.hidesUser('beto'), isTrue);
      expect(state.hidesUser('caro'), isFalse);
    });

    test('el inicio quita bloqueados, silenciados y lo oculto', () {
      final feed = state.feed([
        _rating('ana', 'a1'),
        _rating('beto', 'a1'),
        _rating('caro', 'a1'),
        _rating('dani', 'a1'),
        _rating('dani', 'a2'),
      ]);
      expect(feed.map((e) => e.id), ['dani_a1']);
    });

    test('fuera del inicio, a quien silencié se le sigue viendo', () {
      final shown = state.ratings([
        _rating('ana', 'a1'),
        _rating('caro', 'a1'),
        _rating('dani', 'a2'),
      ]);
      expect(shown.map((e) => e.uid), ['caro']);
    });

    test('respuestas, personas y avisos sin las cuentas bloqueadas', () {
      expect(
        state.replies([_reply('reply-1', 'ana'), _reply('reply-2', 'eva'), _reply('reply-3', 'eva')]).map((r) => r.id),
        ['reply-3'],
      );
      expect(state.people([_person('ana'), _person('beto'), _person('caro')]).map((p) => p.uid), ['caro']);
      expect(
        state.notifications([_notification('ana'), _notification('caro')]).map((n) => n.from.uid),
        ['caro'],
      );
    });

    test('el texto pasa por el filtro solo si está encendido', () {
      const text = 'Este disco es una mierda';
      expect(state.text(text), 'Este disco es una ••••••');
      expect(state.copyWith(filterOffensive: false).text(text), text);
    });

    test('sin nada que esconder, las listas quedan igual', () {
      const empty = ModerationState();
      final all = [_rating('ana', 'a1'), _rating('beto', 'a2')];
      expect(empty.feed(all), hasLength(2));
      expect(empty.ratings(all), hasLength(2));
    });
  });

  group('maskOffensive', () {
    test('tapa palabras completas sin importar mayúsculas ni tildes', () {
      expect(maskOffensive('IMBÉCIL total'), '••••••• total');
      expect(maskOffensive('que Mierda, parce'), 'que ••••••, parce');
      expect(maskOffensive('fuck this'), '•••• this');
    });

    test('no toca palabras que solo se parecen', () {
      // "putativo" contiene "puta"; "Scunthorpe", "cunt".
      expect(maskOffensive('putativo'), 'putativo');
      expect(maskOffensive('Scunthorpe'), 'Scunthorpe');
      expect(maskOffensive('un cono de helado'), 'un cono de helado');
    });

    test('deja los signos, los espacios y los emojis', () {
      expect(maskOffensive('¡idiota! 😐'), '¡••••••! 😐');
      expect(maskOffensive(''), '');
    });

    test('hasOffensive', () {
      expect(hasOffensive('qué discazo'), isFalse);
      expect(hasOffensive('eres un pendejo'), isTrue);
    });
  });

  group('BlockFollowDelta', () {
    test('si se seguían en los dos sentidos, bajan los cuatro contadores', () {
      const d = BlockFollowDelta(iFollowed: true, theyFollowed: true);
      expect([d.myFollowing, d.myFollowers, d.theirFollowers, d.theirFollowing], [-1, -1, -1, -1]);
      expect(d.touchesMe && d.touchesThem, isTrue);
    });

    test('si solo yo le seguía, baja lo mío y sus seguidores', () {
      const d = BlockFollowDelta(iFollowed: true, theyFollowed: false);
      expect([d.myFollowing, d.myFollowers, d.theirFollowers, d.theirFollowing], [-1, 0, -1, 0]);
    });

    test('sin seguimientos no se toca ningún contador', () {
      const d = BlockFollowDelta(iFollowed: false, theyFollowed: false);
      expect(d.touchesMe || d.touchesThem, isFalse);
    });
  });

  group('reportes', () {
    test('el número mostrado tiene cuatro cifras', () {
      final random = math.Random(7);
      for (var i = 0; i < 200; i++) {
        final n = reportNumber(random);
        expect(n, inInclusiveRange(1000, 9999));
      }
    });

    test('los motivos van y vuelven por su clave', () {
      for (final r in ReportReason.values) {
        expect(ReportReason.fromKey(r.key), r);
      }
      expect(ReportReason.fromKey('nada'), ReportReason.other);
      expect(ReportReason.values.map((r) => r.key), [
        'spam',
        'harassment',
        'hate',
        'sexual',
        'impersonation',
        'violence',
        'other',
      ]);
    });

    test('solo los comentarios se ocultan al reportarlos', () {
      expect(ReportTarget.user.isContent, isFalse);
      expect(ReportTarget.rating.isContent, isTrue);
      expect(ReportTarget.reply.isContent, isTrue);
    });

    test('cada motivo tiene título y explicación en los dos idiomas', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l = lookupAppLocalizations(locale);
        for (final r in ReportReason.values) {
          expect(r.title(l), isNotEmpty);
          expect(r.hint(l), isNotEmpty);
          expect(r.short(l), isNotEmpty);
        }
      }
    });
  });

  group('relativeAgo', () {
    final now = DateTime(2026, 10, 2, 15);
    final es = lookupAppLocalizations(const Locale('es'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('en español', () {
      expect(relativeAgo(DateTime(2026, 10, 2, 9), es, now: now), 'hoy');
      expect(relativeAgo(DateTime(2026, 10, 1, 23), es, now: now), 'ayer');
      expect(relativeAgo(DateTime(2026, 9, 30), es, now: now), 'hace 2 días');
      expect(relativeAgo(DateTime(2026, 9, 11), es, now: now), 'hace 3 semanas');
      expect(relativeAgo(DateTime(2026, 9, 25), es, now: now), 'hace 1 semana');
      expect(relativeAgo(DateTime(2026, 5, 2), es, now: now), 'hace 5 meses');
      expect(relativeAgo(DateTime(2024, 9, 2), es, now: now), 'hace 2 años');
    });

    test('en inglés', () {
      expect(relativeAgo(DateTime(2026, 10, 2, 9), en, now: now), 'today');
      expect(relativeAgo(DateTime(2026, 9, 11), en, now: now), '3 weeks ago');
      expect(relativeAgo(DateTime(2026, 8, 30), en, now: now), '1 month ago');
    });
  });
}
