import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/util/tab_reselect.dart';

void main() {
  test('Buscar: abajo, primero sube', () {
    expect(searchReselect(atTop: false, hasText: true), SearchReselect.scrollTop);
    expect(searchReselect(atTop: false, hasText: false), SearchReselect.scrollTop);
  });

  test('Buscar: arriba con texto, lo borra', () {
    expect(searchReselect(atTop: true, hasText: true), SearchReselect.clear);
  });

  test('Buscar: arriba y sin texto, abre el teclado', () {
    expect(searchReselect(atTop: true, hasText: false), SearchReselect.focus);
  });

  test('TabReselect avisa a quien escucha', () {
    final r = TabReselect();
    var n = 0;
    r.addListener(() => n++);
    r.fire();
    r.fire();
    expect(n, 2);
    r.dispose();
  });
}
