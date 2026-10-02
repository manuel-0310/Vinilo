import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/models/support.dart';

AlbumRequest _r(String query, int day) =>
    AlbumRequest(id: '$query$day', uid: 'u', query: query, createdAt: DateTime(2026, 10, day));

void main() {
  test('agrupa lo mismo escrito distinto y ordena por cuántas veces', () {
    final groups = groupRequests([
      _r('Ceratti Bocanda', 1),
      _r('ceratti  bocanda ', 3),
      _r('Kiss Me Again', 2),
      _r('ceratti bocanda', 2),
    ]);
    expect(groups, hasLength(2));
    expect(groups.first.count, 3);
    // El texto del pedido más reciente.
    expect(groups.first.query, 'ceratti  bocanda');
    expect(groups.first.last, DateTime(2026, 10, 3));
    expect(groups.last.query, 'Kiss Me Again');
  });

  test('empatados, el más reciente primero; vacíos fuera', () {
    final groups = groupRequests([_r('a', 1), _r('b', 5), _r('   ', 9)]);
    expect(groups.map((g) => g.query), ['b', 'a']);
  });
}
