import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';
import 'services/services.dart';
import 'theme/vinilo_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ViniloApp(services: Services.create()));
}

class ViniloApp extends StatefulWidget {
  const ViniloApp({super.key, required this.services});

  final Services services;

  @override
  State<ViniloApp> createState() => _ViniloAppState();
}

class _ViniloAppState extends State<ViniloApp> {
  // Un par de temas por color de énfasis; se construyen la primera vez que
  // alguien elige ese color y se reutilizan.
  final Map<int, (ThemeData, ThemeData)> _themes = {};

  (ThemeData, ThemeData) _themesFor(Color seed) {
    return _themes.putIfAbsent(
      seed.toARGB32(),
      () => (
        buildViniloTheme(ViniloPalette.light.withSeed(seed)),
        buildViniloTheme(ViniloPalette.dark.withSeed(seed)),
      ),
    );
  }
  String? _profileUid;
  Stream<UserProfile?>? _profileStream;
  Object? _authError;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    setState(() => _authError = null);
    try {
      await widget.services.auth.ensureSignedIn();
    } catch (e) {
      if (mounted) setState(() => _authError = e);
    }
  }

  Stream<UserProfile?> _profileFor(String uid) {
    if (_profileUid != uid) {
      _profileUid = uid;
      _profileStream = widget.services.users.watch(uid);
    }
    return _profileStream!;
  }

  Widget _app({UserProfile? profile, required Widget home}) {
    final (light, dark) = _themesFor(profile?.color ?? ViniloPalette.defaultSeed);
    return CurrentUser(
      profile: profile,
      child: MaterialApp(
        title: 'Vinilo',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        // Sin perfil (splash, onboarding) la app arranca oscura, que es su
        // carácter; la preferencia vive en el documento del usuario.
        themeMode: profile?.themeMode ?? ThemeMode.dark,
        // La barra de estado sigue al tema; las pantallas con foto de fondo
        // la sobrescriben con su propia AnnotatedRegion.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyleFor(Theme.of(context).brightness),
          child: child ?? const SizedBox.shrink(),
        ),
        home: _HomeSwitcher(child: home),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: widget.services,
      child: StreamBuilder<User?>(
        stream: widget.services.auth.changes,
        builder: (context, authSnap) {
          final user = authSnap.data;
          if (user == null) {
            return _app(
              home: SplashScreen(error: _authError, onRetry: _signIn),
            );
          }
          return StreamBuilder<UserProfile?>(
            stream: _profileFor(user.uid),
            builder: (context, profileSnap) {
              if (profileSnap.hasError) {
                return _app(
                  home: SplashScreen(
                    error: profileSnap.error,
                    onRetry: () => setState(() => _profileUid = null),
                  ),
                );
              }
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return _app(home: const SplashScreen());
              }
              final profile = profileSnap.data;
              return _app(
                profile: profile,
                home: profile == null
                    ? OnboardingScreen(uid: user.uid)
                    : const ShellScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeSwitcher extends StatelessWidget {
  const _HomeSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}
