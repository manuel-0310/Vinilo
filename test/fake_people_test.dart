import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/util/username.dart';

import '../test_driver/fake_people.dart';

void main() {
  test('son seis personas con correo de prueba y @usuario válido y único', () {
    expect(fakePeople.length, 6);
    final usernames = <String>{};
    final emails = <String>{};
    for (final p in fakePeople) {
      expect(p.email.endsWith('@vinilo.test'), isTrue, reason: p.email);
      expect(usernameProblem(p.username), isNull, reason: p.username);
      expect(usernames.add(p.username), isTrue, reason: 'repetido: ${p.username}');
      expect(emails.add(p.email), isTrue, reason: 'repetido: ${p.email}');
      expect(p.name.length, inInclusiveRange(2, 24), reason: p.name);
    }
  });

  test('cada una tiene entre 10 y 20 notas válidas, sin discos repetidos', () {
    for (final p in fakePeople) {
      expect(p.ratings.length, inInclusiveRange(10, 20), reason: p.username);
      final queries = p.ratings.map((r) => r.query).toSet();
      expect(queries.length, p.ratings.length, reason: '${p.username}: disco repetido');
      for (final r in p.ratings) {
        expect(r.score, inInclusiveRange(1, 10), reason: r.query);
        expect((r.note ?? '').length, lessThanOrEqualTo(180), reason: r.query);
      }
      final withNote = p.ratings.where((r) => r.note != null).length;
      expect(withNote, greaterThanOrEqualTo(p.ratings.length ~/ 3), reason: p.username);
    }
  });

  test('favoritos, ranking y lista de discos salen de sus propias notas', () {
    for (final p in fakePeople) {
      final queries = p.ratings.map((r) => r.query).toSet();
      expect(p.favorites.length, 3, reason: p.username);
      expect(p.favoriteArtists.length, 3, reason: p.username);
      expect(queries.containsAll(p.favorites), isTrue, reason: p.username);
      expect(queries.contains(p.rankingFrom), isTrue, reason: p.username);
      expect(queries.containsAll(p.albumList), isTrue, reason: p.username);
      expect(p.albumList.length, greaterThanOrEqualTo(3), reason: p.username);
      expect(p.rankingName.length, inInclusiveRange(1, 60));
      expect(p.albumListName.length, inInclusiveRange(1, 60));
    }
  });

  test('solo tres siguen a Manuel', () {
    expect(fakePeople.where((p) => p.followsManuel).length, 3);
  });
}
