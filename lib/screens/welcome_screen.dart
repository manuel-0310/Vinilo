import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/services.dart';
import '../theme/oklch.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/rating_bars.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_sections.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Primera pantalla sin sesión: el cabezal "Nº 001 · Diario de discos",
/// "VINILO" en grande, una rejilla de 8 portadas (las más calificadas, o
/// los colores planos del prototipo si no llegan) y la invitación. Abajo,
/// las barras de Calificar para probar; al poner una nota aparecen los
/// botones de crear cuenta e iniciar sesión (`WelcomeActions`).
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
                      ],
                    ),
                  ),
                  // Lo mismo que había entre el párrafo y la regla: las
                  // barras son más altas que los botones y así cabe todo
                  // en un iPhone de 874 sin desplazarse.
                  const SizedBox(height: 22),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
                    child: WelcomeActions(
                      onSignUp: () => WelcomeScreen.openSignUp(context),
                      onSignIn: () => WelcomeScreen.openSignIn(context),
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

/// La parte de abajo de la bienvenida. Primero, "Pruébalo" con la nota a la
/// derecha, las barras de Calificar y "Toca o desliza". Mientras nadie toca,
/// las barras se mueven solas como en la landing web (8, 3, 6, 10, 5, 9, 7,
/// cada 1,4 s, con la nota tenue) y "Toca o desliza" late en énfasis. Al
/// soltar el dedo con una nota se deja ver 450 ms; después las barras caen y
/// se desvanecen (200 ms) y suben los botones con rebote, "Crear cuenta"
/// primero y "Ya tengo cuenta" 50 ms después, con un háptico suave al llegar. No se repite mientras la
/// bienvenida siga abierta (al volver de Iniciar sesión siguen los botones);
/// al cerrar sesión la bienvenida es nueva y arranca con las barras.
///
/// Las dos partes ocupan el mismo hueco (el alto de las barras), así lo de
/// arriba no se mueve con el cambio.
class WelcomeActions extends StatefulWidget {
  const WelcomeActions({super.key, required this.onSignUp, required this.onSignIn});

  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  /// Cuánto se ve la nota antes de que empiece la salida.
  static const Duration hold = Duration(milliseconds: 450);
  static const Duration barsOut = Duration(milliseconds: 200);

  /// Cuándo empieza a subir "Crear cuenta" (se monta un poco sobre la
  /// salida de las barras), cuánto tarda y el retraso del segundo botón.
  static const Duration buttonsStart = Duration(milliseconds: 110);
  static const Duration buttonIn = Duration(milliseconds: 420);
  static const Duration buttonStagger = Duration(milliseconds: 50);

  /// La demostración: las notas que van pasando y cada cuánto.
  static const List<int> demo = [8, 3, 6, 10, 5, 9, 7];
  static const Duration demoStep = Duration(milliseconds: 1400);

  @override
  State<WelcomeActions> createState() => _WelcomeActionsState();
}

class _WelcomeActionsState extends State<WelcomeActions> with TickerProviderStateMixin {
  int? _score;

  /// Paso de la demostración; null en cuanto la persona toca.
  int? _demo = 0;
  Timer? _demoTimer;

  /// El latido de "Toca o desliza" mientras dura la demostración.
  late final AnimationController _pulse;

  /// Ya se hizo la animación: se ven los botones.
  bool _revealed = false;
  bool _landed = false;

  late final AnimationController _anim;

  // Todo en una sola línea de tiempo: la espera, la salida de las barras y
  // la llegada de cada botón.
  static final int _total = (WelcomeActions.hold +
          WelcomeActions.buttonsStart +
          WelcomeActions.buttonStagger +
          WelcomeActions.buttonIn)
      .inMilliseconds;

  static Interval _interval(Duration start, Duration length, Curve curve) => Interval(
        start.inMilliseconds / _total,
        (start + length).inMilliseconds / _total,
        curve: curve,
      );

  static final Interval _barsCurve =
      _interval(WelcomeActions.hold, WelcomeActions.barsOut, Curves.easeInCubic);
  static final Duration _firstStart = WelcomeActions.hold + WelcomeActions.buttonsStart;
  static final Interval _signUpCurve =
      _interval(_firstStart, WelcomeActions.buttonIn, Curves.easeOutBack);
  static final Interval _signInCurve = _interval(
      _firstStart + WelcomeActions.buttonStagger, WelcomeActions.buttonIn, Curves.easeOutBack);
  // La opacidad de cada botón, sin rebote, en el primer tercio de su subida.
  static final Interval _signUpFade = _interval(
      _firstStart, WelcomeActions.buttonIn ~/ 3, Curves.easeOut);
  static final Interval _signInFade = _interval(
      _firstStart + WelcomeActions.buttonStagger, WelcomeActions.buttonIn ~/ 3, Curves.easeOut);

  /// Cuánto bajan las barras al irse y desde cuánto más abajo suben los
  /// botones.
  static const double _barsDrop = 90;
  static const double _buttonRise = 96;

  /// Ancho de la nota con su veredicto ("OBRA MAESTRA" mide unos 80).
  static const double _scoreWidth = 96;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: Duration(milliseconds: _total))
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _revealed = true);
      });
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _demoTimer = Timer.periodic(WelcomeActions.demoStep, (_) {
      if (!mounted || _demo == null) return;
      setState(() => _demo = (_demo! + 1) % WelcomeActions.demo.length);
    });
  }

  /// La primera vez que se toca se acaba la demostración.
  void _stopDemo() {
    if (_demo == null) return;
    _demoTimer?.cancel();
    _pulse
      ..stop()
      ..value = 1;
    _demo = null;
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _pulse.dispose();
    _anim.dispose();
    super.dispose();
  }

  /// El háptico cuando "Crear cuenta" llega arriba.
  void _onTick() {
    if (_landed || _anim.value < _signUpCurve.end) return;
    _landed = true;
    HapticFeedback.lightImpact();
  }

  void _changed(int score) {
    // Volvió a tocar mientras se veía la nota: se espera al nuevo soltar.
    if (_anim.value < _barsCurve.begin) _anim.reset();
    setState(() {
      _stopDemo();
      _score = score;
    });
  }

  void _released() {
    if (_score == null || _revealed) return;
    // Mientras las barras no empiecen a irse, soltar otra vez vuelve a
    // contar la espera desde cero.
    if (_anim.value < _barsCurve.begin) _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final score = _score;
    final preview = _demo == null ? null : WelcomeActions.demo[_demo!];
    final shown = score ?? preview;

    final bars = Column(
      key: const ValueKey('welcome-bars'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: VMono(
                l.welcomeTryIt,
                key: const ValueKey('welcome-invite'),
                size: 10,
                tracking: 0.06,
                height: 1.4,
              ),
            ),
            const SizedBox(width: 16),
            // Ancho y alto fijos (el veredicto más largo cabe), así elegir
            // una nota no parte la invitación en otra línea.
            SizedBox(
              key: const ValueKey('welcome-score'),
              width: _scoreWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    shown == null ? '—' : '$shown',
                    maxLines: 1,
                    style: VText.display(
                      48,
                      weight: 700,
                      height: 0.85,
                      tracking: 0,
                      color: score == null ? c.inkA(0.28) : c.accentText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  VMono(
                    shown == null ? ' ' : Score.label(shown, l),
                    size: 10,
                    tracking: 0.06,
                    color: score == null ? c.inkA(0.28) : c.accentText,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RatingBars(value: score, preview: preview, onChanged: _changed, onEnd: _released),
        const SizedBox(height: 8),
        FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1)
              .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: VMono(
            l.rateSheetHint,
            key: const ValueKey('welcome-hint'),
            size: 10,
            tracking: 0.06,
            color: preview != null ? c.accentText : c.ink4,
          ),
        ),
      ],
    );

    final buttons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _rising(
          _signUpCurve,
          _signUpFade,
          VPrimaryButton(
            key: const ValueKey('welcome-signup'),
            label: l.welcomeSignUp,
            onPressed: widget.onSignUp,
          ),
        ),
        const SizedBox(height: 8),
        _rising(
          _signInCurve,
          _signInFade,
          VSecondaryButton(
            key: const ValueKey('welcome-signin'),
            label: l.welcomeSignIn,
            onPressed: widget.onSignIn,
          ),
        ),
      ],
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Ya ido, sigue ocupando su sitio para que nada se mueva.
        Visibility(
          visible: !_revealed,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              final t = _barsCurve.transform(_anim.value);
              // Una vez que empiezan a irse, ya no se tocan.
              return IgnorePointer(
                ignoring: _anim.value >= _barsCurve.begin,
                child: Transform.translate(
                  offset: Offset(0, _barsDrop * t),
                  child: Opacity(opacity: 1 - t, child: child),
                ),
              );
            },
            child: bars,
          ),
        ),
        IgnorePointer(ignoring: !_revealed, child: buttons),
      ],
    );
  }

  /// Un botón que sube desde abajo con rebote (la curva se pasa un poco y
  /// vuelve) y aparece en el primer tercio.
  Widget _rising(Interval move, Interval fade, Widget child) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = move.transform(_anim.value);
        final opacity = fade.transform(_anim.value);
        return Transform.translate(
          offset: Offset(0, _buttonRise * (1 - t)),
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
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
