import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/misc.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import 'delete_account_sheet.dart';
import 'edit_profile_sheet.dart';
import 'profile_form.dart';

/// Configuración de la app: apariencia (sistema, claro u oscuro) y el color
/// de énfasis. Ambas cosas se guardan en el perfil, así siguen a la persona.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    // Al borrar la cuenta, esta pantalla puede quedarse un instante sin
    // perfil antes de cerrarse.
    final me = CurrentUser.maybeOf(context);
    if (me == null) return const Scaffold();
    final services = ServicesScope.of(context);
    final l10n = context.l10n;
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
                        l10n.settingsTitle,
                        style: VText.display(38, height: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsSubtitle,
                        style: VText.ui(13, color: c.text2),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        l10n.settingsProfile,
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 10),
                      _ProfileRow(profile: me),
                      const SizedBox(height: 34),
                      Text(
                        l10n.settingsAppearance,
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
                        l10n.settingsLanguage,
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 10),
                      _LanguageRow(
                        language: me.language,
                        onChanged: (language) {
                          HapticFeedback.selectionClick();
                          services.users.setLanguage(me.uid, language);
                        },
                      ),
                      const SizedBox(height: 34),
                      Text(
                        l10n.settingsAccent,
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.settingsAccentBody,
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
                      const SizedBox(height: 34),
                      Text(
                        l10n.settingsAccount,
                        style: VText.label(11, color: c.text3),
                      ),
                      const SizedBox(height: 10),
                      _AccountCard(profile: me),
                      const SizedBox(height: 12),
                      SheetAction(
                        key: const ValueKey('delete-account'),
                        icon: Icons.delete_forever_rounded,
                        label: l10n.deleteAccount,
                        hint: l10n.deleteAccountHint,
                        danger: true,
                        onTap: () => showDeleteAccount(context),
                      ),
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
    final l10n = context.l10n;
    final options = [
      (ThemeMode.system, l10n.themeSystem, Icons.brightness_auto_rounded, 'system'),
      (ThemeMode.light, l10n.themeLight, Icons.light_mode_rounded, 'light'),
      (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_rounded, 'dark'),
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

/// Sistema (el idioma del teléfono), español o inglés.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.onChanged});

  /// "es", "en" o null (sistema).
  final String? language;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <(String?, String, IconData, String)>[
      (null, l10n.languageSystem, Icons.phone_iphone_rounded, 'system'),
      ('es', 'Español', Icons.translate_rounded, 'es'),
      ('en', 'English', Icons.translate_rounded, 'en'),
    ];
    return Row(
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeChoice(
              key: ValueKey('language-${o.$4}'),
              label: o.$2,
              icon: o.$3,
              selected: language == o.$1,
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

/// Tu foto, tu nombre y tu @usuario; al tocarla se edita el perfil (antes
/// era un botón aparte en el encabezado del perfil).
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      color: c.surface.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('edit-profile'),
        onTap: () => showEditProfile(context, profile),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              UserAvatar(
                name: profile.name,
                color: profile.color,
                url: profile.avatarUrl,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(16, weight: 700),
                    ),
                    if (profile.username != null)
                      Text(
                        profile.handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(13, color: c.text2),
                      ),
                  ],
                ),
              ),
              Text(
                context.l10n.editProfile,
                style: VText.ui(14, weight: 700, color: c.accent),
              ),
              Icon(Icons.chevron_right_rounded, color: c.accent),
            ],
          ),
        ),
      ),
    );
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
          title: Text(ctx.l10n.signOutTitle, style: VText.display(28)),
          content: Text(
            ctx.l10n.signOutBody,
            style: VText.ui(14, color: c.text2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.cancel),
            ),
            TextButton(
              key: const ValueKey('sign-out-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.l10n.signOut,
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
                context.l10n.signOut,
                style: VText.ui(14, weight: 700, color: c.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
