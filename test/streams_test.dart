import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/util/streams.dart';

void main() {
  test('combineLatestAll espera a que todos emitan y luego sigue cada cambio', () async {
    final a = StreamController<int>();
    final b = StreamController<int>();
    final out = <List<int>>[];
    final sub = combineLatestAll([a.stream, b.stream]).listen(out.add);
    a.add(1);
    await Future<void>.delayed(Duration.zero);
    expect(out, isEmpty);
    b.add(10);
    await Future<void>.delayed(Duration.zero);
    expect(out, [[1, 10]]);
    a.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(out, [[1, 10], [2, 10]]);
    await sub.cancel();
    await a.close();
    await b.close();
  });

  test('sin streams emite una lista vacía', () async {
    expect(await combineLatestAll<int>(const []).toList(), [<int>[]]);
  });
}
