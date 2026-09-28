import 'package:flutter/widgets.dart';

/// Aviso de que se volvió a tocar la pestaña que ya estaba activa en la
/// barra de abajo. El shell tiene uno por pestaña y cada pantalla decide qué
/// hacer (subir hasta arriba, limpiar la búsqueda…).
class TabReselect extends ChangeNotifier {
  void fire() => notifyListeners();
}

/// Qué hace Buscar al volver a tocar su pestaña.
enum SearchReselect { scrollTop, clear, focus }

/// Primero sube hasta arriba; ya arriba, borra la búsqueda si hay algo
/// escrito y, con el campo vacío, abre el teclado.
SearchReselect searchReselect({required bool atTop, required bool hasText}) {
  if (!atTop) return SearchReselect.scrollTop;
  return hasText ? SearchReselect.clear : SearchReselect.focus;
}

/// Si el desplazamiento está (casi) arriba del todo.
bool isAtTop(ScrollController controller) =>
    !controller.hasClients || controller.offset <= 1;

/// Sube hasta arriba con animación.
Future<void> scrollToTop(ScrollController controller) async {
  if (!controller.hasClients) return;
  await controller.animateTo(
    0,
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
  );
}
