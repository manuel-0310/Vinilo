import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'score.dart';

/// Paleta de Vinilo, en dos versiones: carbón cálido (oscura) y papel cálido
/// (clara). Se obtiene con `VColors.of(context)`; nunca hay negro ni blanco
/// puros. El énfasis (`accent`) sale del color que eligió la persona
/// (`seed`), ajustado al tema con `withSeed`; por defecto es el ámbar.
class ViniloPalette extends ThemeExtension<ViniloPalette> {
  const ViniloPalette({
    required this.brightness,
    this.seed = defaultSeed,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.success,
  });

  /// Color de énfasis por defecto (el primero de `VColors.accentPalette`).
  static const Color defaultSeed = Color(0xFFE8A04B);

  final Brightness brightness;

  /// Color elegido por la persona, sin ajustar. `accent` es su versión
  /// adaptada a este tema.
  final Color seed;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color text;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color success;

  bool get isDark => brightness == Brightness.dark;

  /// Negro en oscuro, blanco en claro: para velos, sombras y vidrio.
  Color get scrim => isDark ? Colors.black : Colors.white;

  /// Color de una nota, legible sobre este fondo.
  Color score(num value) => Score.color(value, accent: accent, light: !isDark);

  /// Color de una nota sobre un fondo siempre oscuro (la insignia sobre las
  /// portadas), sea cual sea el tema.
  Color scoreOnDark(num value) =>
      Score.color(value, accent: accentFor(seed, Brightness.dark));

  /// La misma paleta con el énfasis derivado de `seed`: ajusta luminosidad y
  /// saturación al tema y calcula el color del texto encima.
  ViniloPalette withSeed(Color seed) {
    final accent = accentFor(seed, brightness);
    return copyWith(seed: seed, accent: accent, onAccent: onAccentFor(accent));
  }

  static const ViniloPalette dark = ViniloPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0F0E0C),
    surface: Color(0xFF181613),
    surface2: Color(0xFF211E1A),
    surface3: Color(0xFF2B2722),
    line: Color(0x16FFFFFF),
    text: Color(0xFFF4EFE6),
    text2: Color(0xFFA9A296),
    text3: Color(0xFF6F695F),
    accent: Color(0xFFE8A04B),
    onAccent: Color(0xFF1B1408),
    danger: Color(0xFFD26A5C),
    success: Color(0xFF8DBB7A),
  );

  static const ViniloPalette light = ViniloPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF4EFE6),
    surface: Color(0xFFFBF8F2),
    surface2: Color(0xFFEDE6DA),
    surface3: Color(0xFFE1D9CB),
    line: Color(0x1F1B1712),
    text: Color(0xFF1D1913),
    text2: Color(0xFF6B6559),
    text3: Color(0xFF988F80),
    accent: Color(0xFFB8731A),
    onAccent: Color(0xFF1B1408),
    danger: Color(0xFFB94A3C),
    success: Color(0xFF4F8A3F),
  );

  @override
  ViniloPalette copyWith({
    Brightness? brightness,
    Color? seed,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? text,
    Color? text2,
    Color? text3,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? success,
  }) {
    return ViniloPalette(
      brightness: brightness ?? this.brightness,
      seed: seed ?? this.seed,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  @override
  ViniloPalette lerp(ThemeExtension<ViniloPalette>? other, double t) {
    if (other is! ViniloPalette) return this;
    return ViniloPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      seed: Color.lerp(seed, other.seed, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// Acceso a la paleta del tema activo y a los colores fijos.
class VColors {
  VColors._();

  static ViniloPalette of(BuildContext context) =>
      Theme.of(context).extension<ViniloPalette>() ?? ViniloPalette.dark;

  /// Colores que puede elegir cada persona: su avatar, su resplandor y el
  /// énfasis de toda la app cuando es la propia (se ajustan a cada tema).
  static const List<Color> accentPalette = [
    Color(0xFFE8A04B),
    Color(0xFFD26A5C),
    Color(0xFF8DBB7A),
    Color(0xFF5FA8D3),
    Color(0xFFB08CF0),
    Color(0xFFE07BB0),
    Color(0xFF4FC3B0),
    Color(0xFFF2D06B),
    // Ronda 6: cobalto, cereza, esmeralda, mandarina, lima y magenta.
    Color(0xFF5B7FE8),
    Color(0xFFE0546E),
    Color(0xFF3FAE7A),
    Color(0xFFF08A3C),
    Color(0xFFB5CF5A),
    Color(0xFFC45BD6),
  ];
}

/// Tipografía: Instrument Serif para lo editorial, Manrope para la interfaz.
/// Sin `color`, el texto hereda el del tema (`DefaultTextStyle`).
class VText {
  VText._();

  static const String serif = 'InstrumentSerif';
  static const String sans = 'Manrope';

  static TextStyle display(
    double size, {
    Color? color,
    double height = 1.0,
    bool italic = false,
    double letterSpacing = -0.5,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle ui(
    double size, {
    int weight = 500,
    Color? color,
    double height = 1.3,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: _weight(weight),
      fontVariations: [FontVariation('wght', weight.toDouble())],
    );
  }

  /// Etiquetas pequeñas en mayúsculas con tracking amplio.
  static TextStyle label(double size, {Color? color}) {
    return ui(size, weight: 700, color: color, letterSpacing: 1.4, height: 1.2);
  }

  static FontWeight _weight(int w) =>
      FontWeight.values[((w ~/ 100) - 1).clamp(0, 8)];
}

class VSpace {
  VSpace._();
  static const double page = 20;
  static const double tabBarClearance = 110;
}

ThemeData buildViniloTheme(ViniloPalette p) {
  final scheme = p.isDark
      ? ColorScheme.dark(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.accent,
          onSecondary: p.onAccent,
          surface: p.surface,
          onSurface: p.text,
          error: p.danger,
          onError: Colors.white,
          outline: p.line,
          surfaceContainerHighest: p.surface3,
        )
      : ColorScheme.light(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.accent,
          onSecondary: p.onAccent,
          surface: p.surface,
          onSurface: p.text,
          error: p.danger,
          onError: Colors.white,
          outline: p.line,
          surfaceContainerHighest: p.surface3,
        );

  final base = ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: VText.sans,
  );

  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  return base.copyWith(
    extensions: [p],
    textTheme: base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
      fontFamily: VText.sans,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface3,
      contentTextStyle: VText.ui(14, color: p.text),
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.33),
      selectionHandleColor: p.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      hintStyle: VText.ui(15, color: p.text3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: p.accent.withValues(alpha: 0.7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: p.surface3,
        disabledForegroundColor: p.text3,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: VText.ui(16, weight: 700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.text2,
        textStyle: VText.ui(14, weight: 600),
      ),
    ),
    iconTheme: IconThemeData(color: p.text),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}

/// Estilo de la barra de estado según el tema: iconos claros sobre fondo
/// oscuro y viceversa.
SystemUiOverlayStyle overlayStyleFor(Brightness brightness) =>
    brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
