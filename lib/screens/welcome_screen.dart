import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/oklch.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_ruler.dart';
import '../widgets/v_sections.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Primera pantalla sin sesión: el cabezal "Nº 001 · Diario de discos",
/// "VINILO" en grande, una rejilla de 8 portadas (las más calificadas, o
/// los colores planos del prototipo si no llegan), la invitación, la regla
/// del 1 al 10 y los botones de crear cuenta e iniciar sesión.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static Future<void> openSignUp(BuildContext context) {
    return Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  static Future<void> openSignIn(BuildContext context) {
    return Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<List<String>>? _covers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _covers ??= ServicesScope.of(context).web.welcomeCovers();
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final bottomPad = math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const WelcomeMasthead(),
                        FutureBuilder<List<String>>(
                          future: _covers,
                          builder: (context, snap) =>
                              _CoverGrid(covers: snap.data ?? const []),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          l.welcomeHeadline,
                          style: VText.display(
                            30,
                            weight: 600,
                            stretch: 80,
                            height: 1.02,
                            tracking: -0.015,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.welcomeBody,
                          style: VText.ui(15, color: c.ink2, height: 1.45),
                        ),
                        const SizedBox(height: 22),
                        RulerCells(
                          selected: 10,
                          lines: true,
                          height: 30,
                          fontSize: 11,
                          numberColor: c.ink4,
                          selectedWeight: 500,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VPrimaryButton(
                          key: const ValueKey('welcome-signup'),
                          label: l.welcomeSignUp,
                          onPressed: () => WelcomeScreen.openSignUp(context),
                        ),
                        const SizedBox(height: 8),
                        VSecondaryButton(
                          key: const ValueKey('welcome-signin'),
                          label: l.welcomeSignIn,
                          onPressed: () => WelcomeScreen.openSignIn(context),
                        ),
                      ],
                    ),
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

/// Cabezal de la bienvenida: "Nº 001 · Diario de discos" con una línea
/// debajo y "VINILO" en 128. La pantalla de carga lo usa sin la primera
/// fila (pero con su hueco), así "VINILO" no se mueve al pasar de una a
/// otra.
class WelcomeMasthead extends StatelessWidget {
  const WelcomeMasthead({super.key, this.showOverline = true});

  final bool showOverline;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: showOverline ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VMono(l.welcomeIssue),
                VMono(l.welcomeOverline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.appName.toUpperCase(),
          key: const ValueKey('welcome-logo'),
          maxLines: 1,
          softWrap: false,
          style: VText.display(128, weight: 900, height: 0.86),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Rejilla de 4×2 portadas con separación de 2. Mientras no llegan (o si
/// la función no responde) se ven los colores planos del prototipo.
class _CoverGrid extends StatelessWidget {
  const _CoverGrid({required this.covers});

  final List<String> covers;

  static final List<Color> _fallback = const [
    Oklch(0.42, 0.14, 255),
    Oklch(0.55, 0.17, 15),
    Oklch(0.86, 0.01, 250),
    Oklch(0.52, 0.13, 150),
    Oklch(0.62, 0.21, 38),
    Oklch(0.40, 0.05, 70),
    Oklch(0.88, 0.03, 220),
    Oklch(0.5, 0.2, 25),
  ].map((o) => o.toColor()).toList();

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) => Expanded(
          child: AlbumCover(
            key: ValueKey('welcome-cover-$i'),
            url: i < covers.length ? covers[i] : null,
            placeholderColor: _fallback[i],
          ),
        );
    Widget row(int from) => Row(
          children: [
            for (var i = from; i < from + 4; i++) ...[
              if (i > from) const SizedBox(width: 2),
              cell(i),
            ],
          ],
        );
    return Column(
      children: [row(0), const SizedBox(height: 2), row(4)],
    );
  }
}
