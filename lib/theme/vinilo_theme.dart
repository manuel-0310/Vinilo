import 'package:flutter/material.dart';

/// Paleta de Vinilo: carbón cálido, texto marfil y ámbar como acento.
class VColors {
  VColors._();

  static const Color bg = Color(0xFF0F0E0C);
  static const Color surface = Color(0xFF181613);
  static const Color surface2 = Color(0xFF211E1A);
  static const Color surface3 = Color(0xFF2B2722);
  static const Color line = Color(0x16FFFFFF);
  static const Color text = Color(0xFFF4EFE6);
  static const Color text2 = Color(0xFFA9A296);
  static const Color text3 = Color(0xFF6F695F);
  static const Color accent = Color(0xFFE8A04B);
  static const Color onAccent = Color(0xFF1B1408);
  static const Color danger = Color(0xFFD26A5C);
  static const Color success = Color(0xFF8DBB7A);

  /// Colores que puede elegir cada persona para su avatar.
  static const List<Color> avatarPalette = [
    Color(0xFFE8A04B),
    Color(0xFFD26A5C),
    Color(0xFF8DBB7A),
    Color(0xFF5FA8D3),
    Color(0xFFB08CF0),
    Color(0xFFE07BB0),
    Color(0xFF4FC3B0),
    Color(0xFFF2D06B),
  ];
}

/// Tipografía: Instrument Serif para lo editorial, Manrope para la interfaz.
class VText {
  VText._();

  static const String serif = 'InstrumentSerif';
  static const String sans = 'Manrope';

  static TextStyle display(
    double size, {
    Color color = VColors.text,
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
    Color color = VColors.text,
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
  static TextStyle label(double size, {Color color = VColors.text3}) {
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

ThemeData buildViniloTheme() {
  const scheme = ColorScheme.dark(
    primary: VColors.accent,
    onPrimary: VColors.onAccent,
    secondary: VColors.accent,
    onSecondary: VColors.onAccent,
    surface: VColors.surface,
    onSurface: VColors.text,
    error: VColors.danger,
    onError: Colors.white,
    outline: VColors.line,
    surfaceContainerHighest: VColors.surface3,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: VColors.bg,
    fontFamily: VText.sans,
  );

  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: VColors.text,
      displayColor: VColors.text,
      fontFamily: VText.sans,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: VColors.text,
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
      backgroundColor: VColors.surface3,
      contentTextStyle: VText.ui(14, color: VColors.text),
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
    dividerTheme: const DividerThemeData(
      color: VColors.line,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: VColors.accent,
      selectionColor: Color(0x55E8A04B),
      selectionHandleColor: VColors.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VColors.surface2,
      hintStyle: VText.ui(15, color: VColors.text3),
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
        borderSide: BorderSide(color: VColors.accent.withValues(alpha: 0.7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: VColors.accent,
        foregroundColor: VColors.onAccent,
        disabledBackgroundColor: VColors.surface3,
        disabledForegroundColor: VColors.text3,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: VText.ui(16, weight: 700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VColors.text2,
        textStyle: VText.ui(14, weight: 600),
      ),
    ),
    iconTheme: const IconThemeData(color: VColors.text),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: VColors.accent,
    ),
  );
}
