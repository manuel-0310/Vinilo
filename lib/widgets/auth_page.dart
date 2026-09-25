import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import 'v_buttons.dart';
import 'v_icons.dart';
import 'v_sections.dart';

/// Andamio de las pantallas de acceso: Iniciar sesión y Crear cuenta, y las
/// que no tienen diseño propio con el mismo carácter (completar el perfil,
/// elegir el @usuario, guardar una sesión anónima). Arriba, volver con
/// borde; luego "VINILO" en mono, el título condensado de 64 y los campos;
/// abajo, a 38 del borde, los botones. Si el teclado no deja sitio, todo se
/// desplaza.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
    this.showBack = true,
    this.bodyTop = 36,
  });

  /// Título en dos líneas ("Iniciar\nsesión").
  final String title;

  /// Los campos, debajo del título.
  final Widget body;

  /// Los botones de abajo.
  final Widget? bottom;

  /// Sin volver (las pantallas que son la raíz), el título queda donde
  /// mismo.
  final bool showBack;

  /// Aire entre el título y los campos (36 al entrar, 32 al crear la
  /// cuenta).
  final double bodyTop;

  /// Volver (40) más su relleno de arriba (4).
  static const double _backHeight = 44;

  @override
  Widget build(BuildContext context) {
    final bottomPad = math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBack)
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
                    padding: EdgeInsets.fromLTRB(24, showBack ? 28 : 28 + _backHeight, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VMono(context.l10n.appName),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          key: const ValueKey('auth-title'),
                          style: VText.display(64, weight: 800, height: 0.86, tracking: 0),
                        ),
                        SizedBox(height: bodyTop),
                        body,
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Spacer(),
                  if (bottom != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
                      child: bottom,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La raya con "o" en medio entre "Entrar" y los botones de Apple y Google.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: c.line)),
          const SizedBox(width: 12),
          VMono(context.l10n.authOr, size: 10, color: c.ink4),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: c.line)),
        ],
      ),
    );
  }
}

/// "¿No tienes cuenta? Crear cuenta": la pregunta apagada y el enlace
/// subrayado en tinta, centrados. Toda la línea responde al toque.
class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              question,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VText.ui(14, color: c.ink2),
            ),
          ),
          VTextLink(action, onTap: onTap),
        ],
      ),
    );
  }
}

/// Párrafo de las pantallas de acceso sin diseño propio (15, apagado).
class AuthParagraph extends StatelessWidget {
  const AuthParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Text(text, style: VText.ui(15, color: c.ink2, height: 1.45));
  }
}
