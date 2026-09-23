import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vinilo_theme.dart';
import 'misc.dart';
import 'vinyl_disc.dart';

/// Andamio de las pantallas de cuenta (bienvenida, crear cuenta, iniciar
/// sesión, guardar la sesión, elegir @usuario): vinilo girando, un titular
/// editorial, una explicación breve y el contenido. Con `showBack` pone el
/// botón de volver en el mismo sitio que el resto de la app.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = false,
    this.footer,
    this.leading,
  });

  final Widget title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  /// Algo debajo del contenido (enlaces secundarios).
  final Widget? footer;

  /// Reemplaza al vinilo (por ejemplo, el avatar de la persona).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, showBack ? 66 : 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: leading ?? const SpinningVinyl(size: 44),
                  ),
                  const SizedBox(height: 30),
                  DefaultTextStyle.merge(
                    style: VText.display(42, height: 0.98),
                    child: title,
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06),
                  if (subtitle != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      subtitle!,
                      style: VText.ui(15, color: c.text2, height: 1.45),
                    ).animate().fadeIn(delay: 120.ms, duration: 450.ms),
                  ],
                  const SizedBox(height: 34),
                  child.animate().fadeIn(delay: 220.ms, duration: 450.ms),
                  if (footer != null) ...[
                    const SizedBox(height: 22),
                    footer!.animate().fadeIn(delay: 320.ms, duration: 450.ms),
                  ],
                ],
              ),
            ),
          ),
          if (showBack)
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

/// Botón secundario de las pantallas de cuenta: mismo tamaño que el
/// principal, sobre la segunda superficie.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(label, style: VText.ui(16, weight: 700, color: c.text)),
          ),
        ),
      ),
    );
  }
}
