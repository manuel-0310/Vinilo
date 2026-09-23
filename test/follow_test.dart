import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/follow.dart';

void main() {
  group('followDelta', () {
    test('seguir a alguien nuevo crea el seguimiento y suma uno a cada lado', () {
      final d = followDelta(me: 'a', other: 'b', exists: false, follow: true);
      expect(d.createEdge, isTrue);
      expect(d.deleteEdge, isFalse);
      expect(d.followersDelta, 1);
      expect(d.followingDelta, 1);
      expect(d.isNoop, isFalse);
    });

    test('dejar de seguir borra el seguimiento y resta uno a cada lado', () {
      final d = followDelta(me: 'a', other: 'b', exists: true, follow: false);
      expect(d.createEdge, isFalse);
      expect(d.deleteEdge, isTrue);
      expect(d.followersDelta, -1);
      expect(d.followingDelta, -1);
    });

    test('volver a seguir a quien ya sigo no toca los contadores', () {
      final d = followDelta(me: 'a', other: 'b', exists: true, follow: true);
      expect(d.isNoop, isTrue);
      expect(d.followersDelta, 0);
      expect(d.followingDelta, 0);
    });

    test('dejar de seguir a quien no seguía tampoco', () {
      final d = followDelta(me: 'a', other: 'b', exists: false, follow: false);
      expect(d.isNoop, isTrue);
    });

    test('nadie puede seguirse a sí mismo', () {
      expect(
        followDelta(me: 'a', other: 'a', exists: false, follow: true).isNoop,
        isTrue,
      );
      expect(
        followDelta(me: 'a', other: 'a', exists: true, follow: false).isNoop,
        isTrue,
      );
    });

    test('una ida y vuelta deja los contadores como estaban', () {
      var followers = 4;
      var following = 9;
      final on = followDelta(me: 'a', other: 'b', exists: false, follow: true);
      followers = applyCounter(followers, on.followersDelta);
      following = applyCounter(following, on.followingDelta);
      expect((followers, following), (5, 10));
      final off = followDelta(me: 'a', other: 'b', exists: true, follow: false);
      followers = applyCounter(followers, off.followersDelta);
      following = applyCounter(following, off.followingDelta);
      expect((followers, following), (4, 9));
    });
  });

  test('applyCounter nunca baja de cero', () {
    expect(applyCounter(0, -1), 0);
    expect(applyCounter(3, -1), 2);
    expect(applyCounter(0, 1), 1);
  });

  test('el id del seguimiento es follower_followed', () {
    expect(FollowEdge.docId('ana', 'beto'), 'ana_beto');
  });

  test('PersonInfo va y vuelve de un mapa', () {
    const p = PersonInfo(
      uid: 'u1',
      name: 'Ana',
      colorValue: 0xFF5FA8D3,
      username: 'ana_01',
      avatarUrl: 'https://x/a.jpg',
    );
    final back = PersonInfo.fromMap('u1', p.toMap());
    expect(back.name, 'Ana');
    expect(back.username, 'ana_01');
    expect(back.handle, '@ana_01');
    expect(back.colorValue, 0xFF5FA8D3);
    expect(back.avatarUrl, 'https://x/a.jpg');
  });
}
