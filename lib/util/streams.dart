import 'dart:async';

/// Junta varios streams en uno que emite la lista con el último valor de
/// cada uno. Empieza a emitir cuando todos han emitido al menos una vez y
/// vuelve a emitir cada vez que cualquiera cambia. Con la lista vacía emite
/// una lista vacía y termina.
Stream<List<T>> combineLatestAll<T>(List<Stream<T>> streams) {
  if (streams.isEmpty) return Stream.value(const []);
  late StreamController<List<T>> controller;
  final subs = <StreamSubscription<T>>[];
  final latest = List<T?>.filled(streams.length, null);
  final seen = List<bool>.filled(streams.length, false);

  void emit() {
    if (seen.every((s) => s)) {
      controller.add(List<T>.from(latest.cast<T>()));
    }
  }

  controller = StreamController<List<T>>(
    onListen: () {
      for (final (i, s) in streams.indexed) {
        subs.add(
          s.listen(
            (value) {
              latest[i] = value;
              seen[i] = true;
              emit();
            },
            onError: controller.addError,
          ),
        );
      }
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

/// Cada vez que `source` emite, deja de escuchar el stream anterior y pasa a
/// escuchar `next(valor)` (como `switchMap`). El stream que devuelve es uno
/// solo y estable: quien lo pinta lo escucha una vez aunque por dentro la
/// consulta cambie (por ejemplo, cuando cambia a quién sigo).
Stream<R> switchLatest<S, R>(Stream<S> source, Stream<R> Function(S) next) {
  late StreamController<R> controller;
  StreamSubscription<S>? outer;
  StreamSubscription<R>? inner;
  var outerDone = false;
  var innerDone = true;

  controller = StreamController<R>(
    onListen: () {
      outer = source.listen(
        (value) {
          inner?.cancel();
          innerDone = false;
          inner = next(value).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              innerDone = true;
              if (outerDone) controller.close();
            },
          );
        },
        onError: controller.addError,
        onDone: () {
          outerDone = true;
          if (innerDone) controller.close();
        },
      );
    },
    onCancel: () async {
      await inner?.cancel();
      await outer?.cancel();
    },
  );
  return controller.stream;
}
