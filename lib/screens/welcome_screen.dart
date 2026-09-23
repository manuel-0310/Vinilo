import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vinilo_theme.dart';
import '../widgets/auth_page.dart';
import '../widgets/vinyl_disc.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Primera pantalla sin sesión: crear cuenta o iniciar sesión.
class WelcomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Un disco grande asomando por la esquina, como la tapa de un
          // estuche a medio sacar.
          Positioned(
            top: -150,
            right: -170,
            child: IgnorePointer(
              child: Opacity(
                opacity: c.isDark ? 0.55 : 0.35,
                child: SpinningVinyl(
                  size: 380,
                  period: const Duration(seconds: 9),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: SpinningVinyl(size: 44),
                  ),
                  const Spacer(flex: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Tu diario de '),
                        TextSpan(
                          text: 'discos',
                          style: VText.display(50, italic: true, color: c.accent),
                        ),
                        const TextSpan(text: ' empieza aquí.'),
                      ],
                    ),
                    style: VText.display(50, height: 0.98),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
                  const SizedBox(height: 16),
                  Text(
                    'Busca un álbum, ponle nota del 1 al 10 y mira lo que opina la comunidad. Sin estrellas: aquí se habla en números.',
                    style: VText.ui(15, color: c.text2, height: 1.45),
                  ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                  const Spacer(flex: 4),
                  FilledButton(
                    key: const ValueKey('welcome-signup'),
                    onPressed: () => openSignUp(context),
                    child: const Text('Crear cuenta'),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    key: const ValueKey('welcome-signin'),
                    label: 'Ya tengo cuenta',
                    onPressed: () => openSignIn(context),
                  ).animate().fadeIn(delay: 380.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
