import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'models/moderation.dart';
import 'models/user_profile.dart';
import 'screens/link_account_screen.dart';
import 'screens/onboarding_follow_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/onboarding_tastes_screen.dart';
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

class _ViniloAppState extends State<ViniloApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Si hay conexión se comprueba al arrancar y cada vez que la app vuelve
    // al frente; el resto lo avisan las peticiones que fallan.
    WidgetsBinding.instance.addObserver(this);
    widget.services.connectivity.check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.services.connectivity.check();
  }

  // Un par de temas por color de énfasis; se construyen la primera vez que
  // alguien elige ese color y se reutilizan.
  final Map<int, (ThemeData, ThemeData)> _themes = {};

  (ThemeData, ThemeData) _themesFor(Color accent) {
    return _themes.putIfAbsent(
      accent.toARGB32(),
      () => (
        buildViniloTheme(ViniloPalette.light.withAccent(accent)),
        buildViniloTheme(ViniloPalette.dark.withAccent(accent)),
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

  // Bloqueos, silenciados y comentarios ocultos de quien entró: un solo
  // stream por sesión, para que las listas de toda la app los escondan.
  String? _moderationUid;
  Stream<ModerationState>? _moderationStream;

  Stream<ModerationState> _moderationFor(String uid) {
    if (_moderationUid != uid) {
      _moderationUid = uid;
      _moderationStream = widget.services.moderation.watch(uid);
    }
    return _moderationStream!;
  }

  Widget _app({UserProfile? profile, ModerationState? moderation, required Widget home}) {
    // El color guardado puede ser de la paleta de antes del rediseño: se
    // muestra con el más cercano de la nueva.
    final (light, dark) = _themesFor(
      profile == null ? ViniloPalette.defaultAccent : VColors.nearest(profile.color),
    );
    return Moderation(
      state: (moderation ?? const ModerationState())
          .copyWith(filterOffensive: profile?.filterOffensive ?? true),
      child: CurrentUser(
      profile: profile,
      child: MaterialApp(
        title: 'Vinilo',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        // Sin perfil (splash, bienvenida, onboarding) la app arranca oscura,
        // que es su carácter; la preferencia vive en el documento del usuario.
        themeMode: profile?.themeMode ?? ThemeMode.dark,
        // Español o inglés: el que eligió en Configuración o, si no eligió,
        // el del teléfono (con español de respaldo).
        locale: profile?.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supported) => supported.firstWhere(
          (s) => s.languageCode == locale?.languageCode,
          orElse: () => const Locale('es'),
        ),
        // La barra de estado sigue al tema; las pantallas con foto de fondo
        // la sobrescriben con su propia AnnotatedRegion. El texto se queda
        // en el tamaño estándar: el diseño tiene títulos de hasta 128 px y
        // tiene que verse como el prototipo.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyleFor(Theme.of(context).brightness),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 1,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: _HomeSwitcher(child: home),
      ),
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
  /// - cuenta nueva → el onboarding (gustos y, después, seguir gente);
  /// - todo listo → la app.
  Widget _homeFor(User user, UserProfile? profile) {
    if (profile == null) {
      return user.isAnonymous
          ? const WelcomeScreen()
          : OnboardingScreen(uid: user.uid);
    }
    if (user.isAnonymous) return LinkAccountScreen(profile: profile);
    if (profile.username == null) return UsernameScreen(profile: profile);
    // Una cuenta nueva pasa por los dos pasos del onboarding antes de entrar.
    return switch (profile.onboarding) {
      OnboardingStep.tastes => OnboardingTastesScreen(profile: profile),
      OnboardingStep.follow => const OnboardingFollowScreen(),
      null => const ShellScreen(),
    };
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
              final shown = profile;
              if (shown == null || user.isAnonymous) {
                return _app(profile: shown, home: _homeFor(user, shown));
              }
              // Si los bloqueos no se pueden leer, la app sigue sin esconder
              // nada en vez de quedarse en blanco.
              return StreamBuilder<ModerationState>(
                stream: _moderationFor(user.uid),
                builder: (context, moderationSnap) => _app(
                  profile: shown,
                  moderation: moderationSnap.data,
                  home: _homeFor(user, shown),
                ),
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
