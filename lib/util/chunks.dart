/// Parte `items` en trozos de a lo sumo `size` elementos, en orden. Firestore
/// admite hasta 30 valores en una consulta `in`, así que las listas de uids
/// se consultan por trozos y se juntan después.
List<List<T>> chunked<T>(List<T> items, int size) {
  assert(size > 0);
  final out = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    out.add(items.sublist(i, i + size > items.length ? items.length : i + size));
  }
  return out;
}

/// Tope de valores que acepta Firestore en un filtro `in` / `array-contains-any`.
const int firestoreInLimit = 30;
