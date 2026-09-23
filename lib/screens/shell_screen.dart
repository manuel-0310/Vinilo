import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/glass_bar.dart';
import '../widgets/native_tab_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  /// Permite cambiar de pestaña desde fuera (lo usa el driver de pruebas,
  /// que no puede tocar la barra nativa).
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

  bool _checkedSearchFields = false;

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
    if (me != null) ServicesScope.of(context).users.ensureSearchFields(me);
  }

  @override
  void dispose() {
    ShellScreen.tabRequests.removeListener(_onTabRequest);
    ShellScreen.actionRequests.removeListener(_onActionRequest);
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
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final me = CurrentUser.of(context);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigate: _select),
          const SearchScreen(),
          ProfileScreen(uid: me.uid, isMe: true),
        ],
      ),
      bottomNavigationBar: KeyedSubtree(
        key: const ValueKey('tab-bar'),
        child: NativeTabBar.isSupported
            ? _nativeBar(context)
            : _glassBar(context),
      ),
    );
  }

  /// iOS 26+: la barra nativa con Liquid Glass.
  Widget _nativeBar(BuildContext context) {
    final c = VColors.of(context);
    return NativeTabBar(
      items: const [
        NativeTab(label: 'Inicio', icon: 'house', selectedIcon: 'house.fill'),
        NativeTab(label: 'Buscar', icon: 'magnifyingglass'),
        NativeTab(label: 'Perfil', icon: 'person', selectedIcon: 'person.fill'),
      ],
      selected: _index,
      onSelected: _select,
      tint: c.accent,
      unselectedTint: c.text2,
      dark: c.isDark,
    );
  }

  /// Respaldo en Dart para iOS 15 a 18, Android y web.
  Widget _glassBar(BuildContext context) {
    // Row y no Center: el Scaffold da a esta ranura toda la altura de la
    // pantalla y un Center la ocuparía entera, dejando la píldora a mitad.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TabItem(
                    key: const ValueKey('tab-0'),
                    selected: _index == 0,
                    label: 'Inicio',
                    icon: const Icon(Icons.home_rounded, size: 22),
                    onTap: () => _select(0),
                  ),
                  _TabItem(
                    key: const ValueKey('tab-1'),
                    selected: _index == 1,
                    label: 'Buscar',
                    icon: const Icon(Icons.search_rounded, size: 23),
                    onTap: () => _select(1),
                  ),
                  _TabItem(
                    key: const ValueKey('tab-2'),
                    selected: _index == 2,
                    label: 'Perfil',
                    icon: const Icon(Icons.person_rounded, size: 23),
                    onTap: () => _select(2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 16),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(
                color: selected ? c.accent : c.text2,
              ),
              child: icon,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: VText.ui(13, weight: 700, color: c.accent),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
