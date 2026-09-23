import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/music_list.dart';

ListItem track(String id, {String album = 'alb'}) => ListItem(
      id: id,
      name: 'Canción $id',
      artist: 'Alguien',
      albumId: album,
      albumName: 'Disco',
      durationMs: 200000,
    );

ListItem disc(String id) => ListItem(id: id, name: 'Disco $id', artist: 'Alguien', year: 2020);

void main() {
  group('addItems', () {
    test('agrega al final y no repite lo que ya estaba', () {
      final r = addItems([track('a'), track('b')], [track('b'), track('c')]);
      expect(r.items.map((i) => i.id), ['a', 'b', 'c']);
      expect(r.added, 1);
      expect(r.duplicates, 1);
      expect(r.overflow, 0);
      expect(r.nothingAdded, isFalse);
    });

    test('tampoco repite dentro de lo que llega', () {
      final r = addItems([], [track('a'), track('a'), track('b')]);
      expect(r.items.map((i) => i.id), ['a', 'b']);
      expect(r.added, 2);
      expect(r.duplicates, 1);
    });

    test('si todo ya estaba no agrega nada y lo dice', () {
      final r = addItems([disc('x')], [disc('x')]);
      expect(r.nothingAdded, isTrue);
      expect(r.items.length, 1);
      expect(r.message(ListItemType.albums), 'Ya estaba en la lista');
    });

    test('respeta el tope y cuenta lo que no cupo', () {
      final r = addItems([track('a'), track('b')], [track('c'), track('d')], max: 3);
      expect(r.items.map((i) => i.id), ['a', 'b', 'c']);
      expect(r.added, 1);
      expect(r.overflow, 1);
      expect(r.message(ListItemType.tracks), contains('no cupo'));
    });

    test('el mensaje resume agregados y repetidos', () {
      final r = addItems([track('a')], [track('a'), track('b'), track('c')]);
      expect(r.message(ListItemType.tracks), 'Se agregaron 2 canciones · 1 ya estaba');
      final one = addItems([], [disc('z')]);
      expect(one.message(ListItemType.albums), 'Se agregó 1 disco');
    });
  });

  group('reorder', () {
    final base = ['a', 'b', 'c', 'd'];

    test('mover hacia abajo (newIndex viene uno de más, como en Flutter)', () {
      expect(reorder(base, 0, 2), ['b', 'a', 'c', 'd']);
      expect(reorder(base, 0, 4), ['b', 'c', 'd', 'a']);
    });

    test('mover hacia arriba', () {
      expect(reorder(base, 3, 0), ['d', 'a', 'b', 'c']);
      expect(reorder(base, 2, 1), ['a', 'c', 'b', 'd']);
    });

    test('dejarlo donde estaba no cambia nada', () {
      expect(reorder(base, 1, 1), base);
      expect(reorder(base, 1, 2), base);
    });

    test('índices fuera de rango no rompen', () {
      expect(reorder(base, 9, 0), base);
      expect(reorder(base, 0, 99), ['b', 'c', 'd', 'a']);
      expect(reorder(<String>[], 0, 0), isEmpty);
    });

    test('no modifica la lista original', () {
      final copy = [...base];
      reorder(copy, 0, 3);
      expect(copy, base);
    });
  });

  test('removeItem quita por id', () {
    final items = [track('a'), track('b'), track('c')];
    expect(removeItem(items, 'b').map((i) => i.id), ['a', 'c']);
    expect(removeItem(items, 'zzz').length, 3);
  });

  group('ListItem', () {
    test('de una canción guarda el disco y la duración', () {
      const album = Album(
        id: 'alb',
        name: 'OK Computer',
        artist: 'Radiohead',
        year: 1997,
        cover: 'c',
        coverSmall: 's',
      );
      const t = Track(
        id: 't1',
        name: 'Airbag',
        number: 1,
        disc: 1,
        durationMs: 284000,
        explicit: false,
        artists: 'Radiohead',
      );
      final item = ListItem.fromTrack(t, album);
      expect(item.isTrack, isTrue);
      expect(item.meta, '4:44');
      expect(item.subtitle, 'Radiohead · OK Computer');
      expect(item.album.id, 'alb');
      final back = ListItem.fromMap(item.toMap());
      expect(back.albumId, 'alb');
      expect(back.durationMs, 284000);
      expect(back.smallCover, 's');
    });

    test('de un disco guarda el año', () {
      final item = ListItem.fromAlbum(
        const Album(id: 'alb', name: 'Disco', artist: 'X', year: 2016),
      );
      expect(item.isTrack, isFalse);
      expect(item.meta, '2016');
      expect(item.subtitle, 'X');
      expect(item.album.id, 'alb');
      expect(ListItem.fromMap(item.toMap()).year, 2016);
    });
  });

  test('el mosaico toma hasta cuatro portadas distintas', () {
    final list = MusicList(
      id: 'l',
      ownerUid: 'u',
      owner: const PersonInfoStub().info,
      name: 'Top',
      description: '',
      kind: ListKind.ranking,
      itemType: ListItemType.tracks,
      items: [
        for (var i = 0; i < 6; i++)
          ListItem(id: 't$i', name: 'x', artist: 'y', coverSmall: 'c${i ~/ 2}'),
      ],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(list.covers, ['c0', 'c1', 'c2']);
    expect(list.typeLabel, 'Ranking de canciones');
    expect(list.count, 6);
  });
}

class PersonInfoStub {
  const PersonInfoStub();
  PersonInfo get info => const PersonInfo(uid: 'u', name: 'Ana', colorValue: 0xFFFFFFFF);
}
