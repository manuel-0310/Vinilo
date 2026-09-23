import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/link_account_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/username_screen.dart';
import 'screens/welcome_screen.dart';
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
  UserProfile? _lastProfile;

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
        // Sin perfil (splash, bienvenida, onboarding) la app arranca oscura,
        // que es su carácter; la preferencia vive en el documento del usuario.
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

  /// Qué pantalla toca según la sesión y el perfil:
  /// - sin sesión → bienvenida (crear cuenta o iniciar sesión);
  /// - sesión anónima de antes con perfil → guardar la cuenta (vincular
  ///   correo y contraseña, mismo uid);
  /// - sesión anónima sin perfil → no tiene nada que perder: bienvenida;
  /// - cuenta sin perfil → onboarding;
  /// - perfil sin @usuario → elegirlo;
  /// - todo listo → la app.
  Widget _homeFor(User user, UserProfile? profile) {
    if (profile == null) {
      return user.isAnonymous
          ? const WelcomeScreen()
          : OnboardingScreen(uid: user.uid);
    }
    if (user.isAnonymous) return LinkAccountScreen(profile: profile);
    if (profile.username == null) return UsernameScreen(profile: profile);
    return const ShellScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: widget.services,
      child: StreamBuilder<User?>(
        stream: widget.services.auth.changes,
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return _app(home: const SplashScreen());
          }
          final user = authSnap.data;
          if (user == null) {
            return _app(home: const WelcomeScreen());
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
              var profile = profileSnap.data;
              // Al borrar la cuenta el perfil desaparece un momento antes de
              // que se cierre la sesión: mientras tanto se sigue mostrando la
              // app con el último perfil, para que nada salte a medio borrar.
              if (profile == null &&
                  widget.services.account.deleting &&
                  _lastProfile?.uid == user.uid) {
                profile = _lastProfile;
              }
              _lastProfile = profile;
              return _app(
                profile: profile,
                home: _homeFor(user, profile),
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
