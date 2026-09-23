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

  test('switchLatest cambia de stream interno sin volver a escuchar el externo', () async {
    final source = StreamController<String>();
    final inners = <String, StreamController<int>>{
      'a': StreamController<int>(),
      'b': StreamController<int>(),
    };
    final out = <int>[];
    final sub = switchLatest(source.stream, (String k) => inners[k]!.stream).listen(out.add);
    source.add('a');
    await Future<void>.delayed(Duration.zero);
    inners['a']!.add(1);
    await Future<void>.delayed(Duration.zero);
    source.add('b');
    await Future<void>.delayed(Duration.zero);
    // El interno anterior ya no se escucha: lo que emita se pierde.
    expect(inners['a']!.hasListener, isFalse);
    inners['b']!.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(out, [1, 2]);
    await sub.cancel();
    expect(inners['b']!.hasListener, isFalse);
    expect(source.hasListener, isFalse);
  });

  test('switchLatest acepta volver a una clave anterior con un stream nuevo', () async {
    // Seguir, dejar de seguir y volver a seguir: cada vez se pide un stream
    // nuevo, nunca se escucha dos veces el mismo.
    final source = StreamController<int>();
    var built = 0;
    final out = <int>[];
    final sub = switchLatest(source.stream, (int n) {
      built++;
      return Stream.value(n * 10);
    }).listen(out.add);
    for (final n in [1, 0, 1]) {
      source.add(n);
      await Future<void>.delayed(Duration.zero);
    }
    expect(built, 3);
    expect(out, [10, 0, 10]);
    await sub.cancel();
  });
}
