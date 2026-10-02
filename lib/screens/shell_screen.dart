import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/outbox_sync.dart';
import '../services/services.dart';
import '../util/tab_reselect.dart';
import '../widgets/v_bottom_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  /// Permite cambiar de pestaña desde fuera (lo usa el driver de pruebas;
  /// la barra también tiene las llaves `tab-0` a `tab-2`).
  static final ValueNotifier<int?> tabRequests = ValueNotifier<int?>(null);

  /// Pide al shell ejecutar una acción con su BuildContext (el driver de
  /// pruebas la usa para abrir rutas, como el recortador, sin pasar por la
  /// interfaz). Un navigatorKey en MaterialApp no sirve: impide que el
  /// cambio de `home` (splash → shell) llegue a la ruta raíz.
  static final ValueNotifier<void Function(BuildContext)?> actionRequests =
      ValueNotifier(null);

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  /// Volver a tocar la pestaña activa: Inicio y Perfil suben hasta arriba;
  /// Buscar sube, limpia la búsqueda o abre el teclado.
  final List<TabReselect> _reselect = List.generate(3, (_) => TabReselect());

  bool _checkedSearchFields = false;

  /// Sube las notas que quedaron en la cola sin conexión.
  OutboxSync? _outbox;

  /// El perfil del último build: la nota que sube lleva mi nombre y mi foto
  /// de ese momento.
  UserProfile? _me;

  @override
  void initState() {
    super.initState();
    ShellScreen.tabRequests.addListener(_onTabRequest);
    ShellScreen.actionRequests.addListener(_onActionRequest);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedSearchFields) return;
    _checkedSearchFields = true;
    // Los perfiles de antes no tienen el nombre en minúsculas con el que se
    // busca a la gente; se completa una vez al entrar.
    final me = CurrentUser.maybeOf(context);
    if (me == null) return;
    final services = ServicesScope.of(context);
    services.users.ensureSearchFields(me);
    _outbox = OutboxSync(
      connectivity: services.connectivity,
      pendingCount: services.ratings.outbox(me.uid).map((l) => l.length),
      flush: () => services.ratings.flushOutbox(_me ?? me),
    )..start();
  }

  @override
  void dispose() {
    ShellScreen.tabRequests.removeListener(_onTabRequest);
    ShellScreen.actionRequests.removeListener(_onActionRequest);
    _outbox?.dispose();
    for (final r in _reselect) {
      r.dispose();
    }
    super.dispose();
  }

  void _onActionRequest() {
    final action = ShellScreen.actionRequests.value;
    if (action != null && mounted) {
      ShellScreen.actionRequests.value = null;
      action(context);
    }
  }

  void _onTabRequest() {
    final i = ShellScreen.tabRequests.value;
    if (i != null && mounted) {
      _select(i);
      ShellScreen.tabRequests.value = null;
    }
  }

  void _select(int i) {
    if (i == _index) {
      _reselect[i].fire();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final me = CurrentUser.of(context);
    _me = me;
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(reselect: _reselect[0]),
          SearchScreen(reselect: _reselect[1]),
          ProfileScreen(uid: me.uid, isMe: true, reselect: _reselect[2]),
        ],
      ),
      // La barra del rediseño: texto con una raya de énfasis sobre la
      // pestaña activa, igual en todas las plataformas (la nativa de iOS 26
      // quedó registrada en Swift pero ya no se usa).
      bottomNavigationBar: KeyedSubtree(
        key: const ValueKey('tab-bar'),
        child: VBottomBar(
          labels: [l10n.tabHome, l10n.tabSearch, l10n.tabProfile],
          keys: const ['tab-0', 'tab-1', 'tab-2'],
          selected: _index,
          onSelected: _select,
        ),
      ),
    );
  }
}
