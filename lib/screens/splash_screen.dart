import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vinilo_theme.dart';
import '../widgets/vinyl_disc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpinningVinyl(size: 76),
            const SizedBox(height: 20),
            Text('Vinilo', style: VText.display(44, italic: true))
                .animate()
                .fadeIn(duration: 600.ms),
            if (error != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'No se pudo iniciar sesión.\n$error',
                  textAlign: TextAlign.center,
                  style: VText.ui(13, color: VColors.text2),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
