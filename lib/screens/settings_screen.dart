import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/misc.dart';
import 'profile_form.dart';

/// Configuración de la app: apariencia (sistema, claro u oscuro) y el color
/// de énfasis. Ambas cosas se guardan en el perfil, así siguen a la persona.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final me = CurrentUser.of(context);
    final services = ServicesScope.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    VSpace.page,
                    topPad + 62,
                    VSpace.page,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración',
                        style: VText.display(38, height: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se guarda en tu perfil y te sigue en cualquier dispositivo.',
                        style: VText.ui(13, color: c.text2),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'APARIENCIA',
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 10),
                      _AppearanceRow(
                        mode: me.themeMode,
                        onChanged: (mode) {
                          HapticFeedback.selectionClick();
                          services.users.setThemeMode(me.uid, mode);
                        },
                      ),
                      const SizedBox(height: 34),
                      Text(
                        'COLOR DE ÉNFASIS',
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tiñe botones, enlaces, la pestaña activa y la escala de las notas. También es el color de tu avatar.',
                        style: VText.ui(13, color: c.text2, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      ColorSwatches(
                        selected: me.colorValue,
                        size: 38,
                        onChanged: (v) {
                          if (v == me.colorValue) return;
                          services.users.setColor(me, v);
                        },
                      ),
                      const SizedBox(height: 22),
                      _AccentPreview(profile: me),
                      const SizedBox(height: 34),
                      Text(
                        'CUENTA',
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 10),
                      _AccountCard(profile: me),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
            ],
          ),
          Positioned(
            top: topPad + 8,
            left: 16,
            child: GlassIconButton(
              key: const ValueKey('back'),
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sistema, claro u oscuro.
class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (ThemeMode.system, 'Sistema', Icons.brightness_auto_rounded, 'system'),
      (ThemeMode.light, 'Claro', Icons.light_mode_rounded, 'light'),
      (ThemeMode.dark, 'Oscuro', Icons.dark_mode_rounded, 'dark'),
    ];
    return Row(
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeChoice(
              key: ValueKey('theme-${o.$4}'),
              label: o.$2,
              icon: o.$3,
              selected: mode == o.$1,
              onTap: () => onChanged(o.$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = selected ? c.accent : c.text2;
    return Material(
      color: selected ? c.accent.withValues(alpha: 0.14) : c.surface2,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? c.accent.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(label, style: VText.ui(13, weight: 700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra el efecto del color elegido: un botón con su texto de contraste,
/// un enlace y la escala de notas del 1 al 10 tal como se verá en la app.
class _AccentPreview extends StatelessWidget {
  const _AccentPreview({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      key: ValueKey('accent-preview-${profile.colorValue}'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Así se ve un botón'),
                ),
              ),
              const SizedBox(width: 14),
              Text('Editar', style: VText.ui(14, weight: 700, color: c.accent)),
            ],
          ),
          const SizedBox(height: 18),
          Text('ESCALA DE NOTAS', style: VText.label(10, color: c.text3)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var n = 1; n <= 10; n++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: c.score(n),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$n',
                        style: VText.display(16, color: c.score(n), height: 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate(key: ValueKey(profile.colorValue)).fadeIn(duration: 350.ms);
  }
}

/// Con qué cuenta se entró y cerrar sesión. Las notas y el perfil se quedan
/// en la cuenta; se vuelve a la bienvenida.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});

  final UserProfile profile;

  Future<void> _signOut(BuildContext context) async {
    final services = ServicesScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = VColors.of(ctx);
        return AlertDialog(
          title: Text('¿Cerrar sesión?', style: VText.display(28)),
          content: Text(
            'Tu perfil y tus notas se quedan en tu cuenta. Para volver, entra con tu correo y tu contraseña.',
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const ValueKey('sign-out-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Cerrar sesión',
                style: VText.ui(14, weight: 700, color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    // Se quitan las rutas empujadas (esta pantalla) para que la bienvenida
    // quede a la vista cuando la sesión se cierre.
    Navigator.of(context).popUntil((r) => r.isFirst);
    await services.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final email = ServicesScope.of(context).auth.email;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.username == null ? profile.name : profile.handle,
            key: const ValueKey('account-handle'),
            style: VText.ui(16, weight: 700),
          ),
          if (email != null) ...[
            const SizedBox(height: 3),
            Text(
              email,
              key: const ValueKey('account-email'),
              style: VText.ui(13, color: c.text2),
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: c.line),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('sign-out'),
              onPressed: () => _signOut(context),
              icon: Icon(Icons.logout_rounded, size: 18, color: c.text),
              label: Text(
                'Cerrar sesión',
                style: VText.ui(14, weight: 700, color: c.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
