import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/vinyl_disc.dart';
import 'profile_form.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final services = ServicesScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpinningVinyl(size: 44),
              const SizedBox(height: 30),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Tu diario de '),
                    TextSpan(
                      text: 'discos',
                      style: VText.display(46, italic: true, color: c.accent),
                    ),
                    const TextSpan(text: ' empieza aquí.'),
                  ],
                ),
                style: VText.display(46, height: 0.98),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),
              Text(
                'Busca un álbum, ponle nota del 1 al 10 y mira lo que opina la comunidad. Sin estrellas: aquí se habla en números.',
                style: VText.ui(15, color: c.text2, height: 1.45),
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
              const SizedBox(height: 36),
              ProfileForm(
                submitLabel: 'Empezar',
                onSubmit: (edit) async {
                  String? url;
                  if (edit.avatar != null) {
                    url = await services.users.uploadAvatar(uid, edit.avatar!);
                  }
                  await services.users.create(
                    uid: uid,
                    name: edit.name,
                    colorValue: edit.colorValue,
                    avatarUrl: url,
                  );
                },
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
