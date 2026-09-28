import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/affinity.dart';
import 'package:no_retiene/models/album.dart';

CommonAlbum common(String id, int mine, int theirs, DateTime at) => CommonAlbum(
      album: Album(id: id, name: id, artist: 'x'),
      mine: mine,
      theirs: theirs,
      at: at,
    );

void main() {
  final albums = [
    common('igual', 9, 9, DateTime(2026, 9, 1)),
    common('uno', 8, 9, DateTime(2026, 8, 1)),
    common('tres', 10, 7, DateTime(2026, 7, 1)),
    common('igual-viejo', 7, 7, DateTime(2026, 1, 1)),
    common('seis', 6, 0, DateTime(2026, 6, 1)),
    common('dos', 6, 8, DateTime(2026, 5, 1)),
  ];

  List<String> ids(AffinityFilter f, {required bool desc}) =>
      affinityView(albums, f, mostDifferentFirst: desc).map((a) => a.album.id).toList();

  test('Todos, más parecidos primero; a igual diferencia, el más reciente', () {
    expect(ids(AffinityFilter.all, desc: false), ['igual', 'igual-viejo', 'uno', 'dos', 'tres', 'seis']);
  });

  test('Todos, más distintos primero', () {
    expect(ids(AffinityFilter.all, desc: true), ['seis', 'tres', 'dos', 'uno', 'igual', 'igual-viejo']);
  });

  test('Coinciden: a 1 punto o menos', () {
    expect(ids(AffinityFilter.match, desc: false), ['igual', 'igual-viejo', 'uno']);
  });

  test('Discrepan: a 2 puntos o más', () {
    expect(ids(AffinityFilter.differ, desc: true), ['seis', 'tres', 'dos']);
  });

  test('orden por defecto: solo "Discrepan" empieza por los más distintos', () {
    expect(affinityDefaultDesc(AffinityFilter.all), isFalse);
    expect(affinityDefaultDesc(AffinityFilter.match), isFalse);
    expect(affinityDefaultDesc(AffinityFilter.differ), isTrue);
  });

  test('las tres pestañas suman todo sin repetir', () {
    final match = albums.where((a) => affinityIn(a, AffinityFilter.match)).length;
    final differ = albums.where((a) => affinityIn(a, AffinityFilter.differ)).length;
    expect(match + differ, albums.length);
  });
}
