import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'delete_account_sheet.dart';
import 'edit_profile_sheet.dart';
import 'profile_form.dart';

/// Configuración: "Configuración" en 50 con su explicación y las secciones
/// Perfil (con "Editar perfil →"), Apariencia, Idioma, Color de énfasis y
/// Cuenta. Debajo, fuera del prototipo, "Cerrar sesión" y "Eliminar
/// cuenta". Todo se guarda en el perfil, así sigue a la persona.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final services = ServicesScope.of(context);
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.signOutTitle,
      message: l.signOutBody,
      confirmLabel: l.signOut,
      confirmKey: const ValueKey('sign-out-confirm'),
    );
    if (!ok || !context.mounted) return;
    // Se quitan las rutas empujadas (esta pantalla) para que la bienvenida
    // quede a la vista cuando la sesión se cierre.
    Navigator.of(context).popUntil((r) => r.isFirst);
    await services.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    // Al borrar la cuenta, esta pantalla puede quedarse un instante sin
    // perfil antes de cerrarse.
    final me = CurrentUser.maybeOf(context);
    if (me == null) return const Scaffold();
    final services = ServicesScope.of(context);
    final l = context.l10n;
    final email = services.auth.email;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    Widget header(String label, {double top = 0, double bottom = 10}) => Container(
          margin: EdgeInsets.only(top: top),
          padding: EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, bottom),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
          child: VMono(label),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: VIconButton(
                        key: const ValueKey('back'),
                        icon: VIcon.back,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.settingsTitle,
                          style: VText.display(50, weight: 800, height: 0.88, tracking: 0),
                        ),
                        const SizedBox(height: 8),
                        Text(l.settingsSubtitle, style: VText.ui(14, color: c.ink2, height: 1.4)),
                      ],
                    ),
                  ),
                  header(l.settingsProfile, top: 20),
                  _ProfileRow(profile: me),
                  header(l.settingsAppearance),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 16),
                    child: SegmentedBoxes(
                      labels: [l.themeSystem, l.themeLight, l.themeDark],
                      keys: const ['theme-system', 'theme-light', 'theme-dark'],
                      selected: switch (me.themeMode) {
                        ThemeMode.system => 0,
                        ThemeMode.light => 1,
                        ThemeMode.dark => 2,
                      },
                      onChanged: (i) {
                        HapticFeedback.selectionClick();
                        services.users.setThemeMode(
                          me.uid,
                          const [ThemeMode.system, ThemeMode.light, ThemeMode.dark][i],
                        );
                      },
                    ),
                  ),
                  header(l.settingsLanguage),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 16),
                    child: SegmentedBoxes(
                      // Los nombres de los idiomas van en su propio idioma.
                      labels: [l.languageSystem, 'Español', 'English'],
                      keys: const ['language-system', 'language-es', 'language-en'],
                      selected: switch (me.language) {
                        'es' => 1,
                        'en' => 2,
                        _ => 0,
                      },
                      onChanged: (i) {
                        HapticFeedback.selectionClick();
                        services.users.setLanguage(me.uid, const [null, 'es', 'en'][i]);
                      },
                    ),
                  ),
                  header(l.settingsAccent, bottom: 0),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 6, VSpace.page, 0),
                    child: Text(
                      l.settingsAccentBody,
                      style: VText.ui(13.5, color: c.ink2, height: 1.4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, 18),
                    child: ColorSwatches(
                      selected: me.colorValue,
                      onChanged: (v) {
                        if (v == me.colorValue) return;
                        services.users.setColor(me, v);
                      },
                    ),
                  ),
                  header(l.settingsAccount),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.username == null ? me.name : me.handle,
                          key: const ValueKey('account-handle'),
                          style: VText.ui(16, weight: 600),
                        ),
                        if (email != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            key: const ValueKey('account-email'),
                            style: VText.ui(13, color: c.ink3),
                          ),
                        ],
                        const SizedBox(height: 24),
                        VSecondaryButton(
                          key: const ValueKey('sign-out'),
                          label: l.signOut,
                          leading: VIconView(VIcon.signOut, size: 16, color: c.ink),
                          trailing: null,
                          onPressed: () => _signOut(context),
                        ),
                        const SizedBox(height: 8),
                        VSecondaryButton(
                          key: const ValueKey('delete-account'),
                          label: l.deleteAccount,
                          leading: VIconView(VIcon.trash, size: 16, color: c.danger),
                          trailing: null,
                          color: c.danger,
                          onPressed: () => showDeleteAccount(context),
                        ),
                        const SizedBox(height: 8),
                        Text(l.deleteAccountHint, style: VText.ui(12.5, color: c.ink4, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: bottomPad + 30)),
          ],
        ),
      ),
    );
  }
}

/// Tu avatar de 44 (relleno de tu color), tu nombre y tu @usuario, y
/// "Editar perfil →" en énfasis; toda la fila abre la edición.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Pressable(
      key: const ValueKey('edit-profile'),
      onTap: () => showEditProfile(context, profile),
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 14),
        child: Row(
          children: [
            // Relleno del énfasis (el color de la persona, ya llevado a la
            // paleta).
            UserAvatar(
              name: profile.name,
              color: c.accent,
              url: profile.avatarUrl,
              size: 44,
              filled: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.ui(16, weight: 600),
                  ),
                  if (profile.username != null)
                    Text(
                      profile.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(13, color: c.ink3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Opacity(
              opacity: pressed ? 0.6 : 1,
              child: Text(
                '${context.l10n.editProfile} →',
                style: VText.ui(14, weight: 500, color: c.accentText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
