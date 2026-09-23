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
