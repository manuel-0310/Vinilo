import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/v_buttons.dart';
import 'welcome_screen.dart';

/// Carga inicial: el fondo y "VINILO" en el mismo sitio que en la
/// bienvenida, así el paso de una a otra no mueve nada. Si falla, el error y
/// "Reintentar".
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WelcomeMasthead(showOverline: false),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  context.l10n.splashError('$error'),
                  style: VText.ui(14, color: c.ink2, height: 1.45),
                ),
                const SizedBox(height: 20),
                VSecondaryButton(
                  label: context.l10n.retry,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
