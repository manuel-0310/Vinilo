import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
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

final es = lookupAppLocalizations(const Locale('es'));
final en = lookupAppLocalizations(const Locale('en'));

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
      expect(r.message(ListItemType.albums, es), 'Ya estaba en la lista');
      expect(r.message(ListItemType.albums, en), 'Already in the list');
    });

    test('respeta el tope y cuenta lo que no cupo', () {
      final r = addItems([track('a'), track('b')], [track('c'), track('d')], max: 3);
      expect(r.items.map((i) => i.id), ['a', 'b', 'c']);
      expect(r.added, 1);
      expect(r.overflow, 1);
      expect(r.message(ListItemType.tracks, es), contains('no cupo'));
    });

    test('el mensaje resume agregados y repetidos', () {
      final r = addItems([track('a')], [track('a'), track('b'), track('c')]);
      expect(r.message(ListItemType.tracks, es), 'Se agregaron 2 canciones · 1 ya estaba');
      expect(r.message(ListItemType.tracks, en), 'Added 2 songs · 1 was already there');
      final one = addItems([], [disc('z')]);
      expect(one.message(ListItemType.albums, es), 'Se agregó 1 disco');
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
    expect(list.typeLabel(es), 'Ranking de canciones');
    expect(list.typeLabel(en), 'Song ranking');
    expect(list.count, 6);
  });

  group('insertItemAt', () {
    ListItem it(String id) => ListItem(id: id, name: id, artist: 'A');
    List<String> ids(List<ListItem> l) => l.map((i) => i.id).toList();

    test('devuelve el elemento a su posición original', () {
      final original = [it('a'), it('b'), it('c')];
      final removed = removeItem(original, 'b');
      expect(ids(insertItemAt(removed, it('b'), 1)), ['a', 'b', 'c']);
    });

    test('al principio y al final', () {
      expect(ids(insertItemAt([it('b')], it('a'), 0)), ['a', 'b']);
      expect(ids(insertItemAt([it('a')], it('b'), 1)), ['a', 'b']);
    });

    test('si la lista se acortó mientras tanto, lo pone al final', () {
      expect(ids(insertItemAt([it('a')], it('z'), 7)), ['a', 'z']);
      expect(ids(insertItemAt([it('a')], it('z'), -3)), ['z', 'a']);
    });

    test('si ya está, no lo duplica', () {
      expect(ids(insertItemAt([it('a'), it('b')], it('a'), 1)), ['a', 'b']);
    });
  });

  test('la portada elegida se conserva al editar nombre o elementos', () {
    final list = MusicList(
      id: 'l',
      ownerUid: 'u',
      owner: const PersonInfoStub().info,
      name: 'Top',
      description: '',
      kind: ListKind.list,
      itemType: ListItemType.albums,
      items: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      coverUrl: 'https://x/portada.jpg',
      coverPath: 'lists/l/1.jpg',
    );
    final edited = list.copyWith(name: 'Otro', items: [ListItem(id: 'a', name: 'a', artist: 'b')]);
    expect(edited.coverUrl, 'https://x/portada.jpg');
    expect(edited.coverPath, 'lists/l/1.jpg');
  });

  group('applyListQuery', () {
    MusicList mk(
      String id,
      String name, {
      ListKind kind = ListKind.list,
      ListItemType type = ListItemType.albums,
      List<ListItem> items = const [],
      int likes = 0,
      int day = 1,
      String description = '',
    }) =>
        MusicList(
          id: id,
          ownerUid: 'u',
          owner: const PersonInfoStub().info,
          name: name,
          description: description,
          kind: kind,
          itemType: type,
          items: items,
          createdAt: DateTime(2026, 9, day),
          updatedAt: DateTime(2026, 9, day),
          likedBy: [for (var i = 0; i < likes; i++) 'x$i'],
        );

    final lists = [
      mk('a', 'Pop perfecto', day: 3, likes: 1, items: [disc('1'), disc('2')]),
      mk('b', 'Kid A, de mejor a peor',
          kind: ListKind.ranking, type: ListItemType.tracks, day: 5, likes: 4,
          items: [track('t1'), track('t2'), track('t3')]),
      mk('c', 'Ánimo', day: 1, description: 'Para días grises',
          items: [ListItem(id: 'k', name: 'Kid A', artist: 'Radiohead')]),
    ];
    List<String> ids(List<MusicList> l) => l.map((x) => x.id).toList();

    test('sin filtros, las más recientes primero', () {
      expect(ids(applyListQuery(lists, const ListQuery())), ['b', 'a', 'c']);
    });

    test('busca en el nombre, la descripción y lo que tiene dentro, sin tildes', () {
      expect(ids(applyListQuery(lists, const ListQuery(text: 'kid a'))), ['b', 'c']);
      expect(ids(applyListQuery(lists, const ListQuery(text: 'radiohead'))), ['c']);
      expect(ids(applyListQuery(lists, const ListQuery(text: 'GRISES'))), ['c']);
      expect(ids(applyListQuery(lists, const ListQuery(text: 'animo'))), ['c']);
    });

    test('filtra por tipo y por contenido', () {
      expect(ids(applyListQuery(lists, const ListQuery(kind: ListKind.ranking))), ['b']);
      expect(ids(applyListQuery(lists, const ListQuery(itemType: ListItemType.albums))), ['a', 'c']);
      expect(
        ids(applyListQuery(lists, const ListQuery(kind: ListKind.list, itemType: ListItemType.tracks))),
        isEmpty,
      );
    });

    test('ordena por nombre, por elementos y por me gusta', () {
      expect(ids(applyListQuery(lists, const ListQuery(sort: ListSort.name))), ['c', 'b', 'a']);
      expect(ids(applyListQuery(lists, const ListQuery(sort: ListSort.size))), ['b', 'a', 'c']);
      expect(ids(applyListQuery(lists, const ListQuery(sort: ListSort.likes))), ['b', 'a', 'c']);
    });

    test('filtrar no cambia la lista original y "cleared" conserva el orden', () {
      final q = const ListQuery(text: 'x', kind: ListKind.ranking, sort: ListSort.name);
      applyListQuery(lists, q);
      expect(ids(lists), ['a', 'b', 'c']);
      expect(q.filtering, isTrue);
      expect(q.cleared().filtering, isFalse);
      expect(q.cleared().sort, ListSort.name);
      expect(q.copyWith(kind: () => null).kind, isNull);
    });
  });
}

class PersonInfoStub {
  const PersonInfoStub();
  PersonInfo get info => const PersonInfo(uid: 'u', name: 'Ana', colorValue: 0xFFFFFFFF);
}
