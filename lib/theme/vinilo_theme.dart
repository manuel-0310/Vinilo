import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'oklch.dart';

/// Paleta de Vinilo ("estuche de vinilo, editorial"): los tokens de la
/// especificación del rediseño. Se obtiene con `VColors.of(context)`. El
/// énfasis (`accent`) es el color que eligió la persona, uno de
/// `VColors.accentPalette`; el texto encima de él es siempre `onAccent`.
///
/// Todo color de la interfaz sale de aquí: el tema claro ("Modo claro" de
/// `ESPECIFICACION.md`) son los mismos tokens con otros valores.
class ViniloPalette extends ThemeExtension<ViniloPalette> {
  const ViniloPalette({
    required this.brightness,
    this.accent = defaultAccent,
    this.accentText = defaultAccent,
    required this.bg,
    required this.sheet,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.line,
    required this.lineSoft,
    required this.lineStrong,
    required this.buttonLine,
    required this.inactive,
    required this.placeholder,
    required this.scrim,
    required this.overButton,
    required this.onAccent,
    required this.success,
    required this.danger,
  });

  /// Bermellón, `oklch(0.7 0.19 38)`: el primero de la paleta.
  static const Color defaultAccent = Color(0xFFFD6A3A);

  final Brightness brightness;

  /// Color de énfasis: botones primarios, enlaces, pestaña activa, punto de
  /// avisos, "Siguiendo", notas, barras, foco de los campos.
  final Color accent;

  /// El énfasis usado como texto o línea fina sobre el fondo ("Ver todo",
  /// notas, "Siguiendo", foco de los campos). En oscuro es `accent`; en
  /// claro, la misma tonalidad y croma con luminosidad 0,52 para que se lea.
  final Color accentText;

  /// Fondo de la app.
  final Color bg;

  /// Fondo de las hojas inferiores.
  final Color sheet;

  /// Relleno de fotos y portadas que todavía no cargan.
  final Color surface;

  /// Texto principal y botón primario neutro.
  final Color ink;

  /// Texto secundario y descripciones (tinta al 62 %).
  final Color ink2;

  /// Etiquetas mono (58 %).
  final Color ink3;

  /// Texto terciario y contadores (50 %).
  final Color ink4;

  /// Separadores principales (14 %).
  final Color line;

  /// Separadores entre filas (8 %).
  final Color lineSoft;

  /// Bordes de botones secundarios y línea de los campos (28 %).
  final Color lineStrong;

  /// Borde de los botones cuadrados de ícono (18 %).
  final Color buttonLine;

  /// Pestañas y opciones no elegidas (55 %).
  final Color inactive;

  /// Texto de ejemplo en los campos vacíos (45 %).
  final Color placeholder;

  /// Velo detrás de una hoja inferior.
  final Color scrim;

  /// Fondo de los botones que van sobre una foto (portada, banner).
  final Color overButton;

  /// Texto sobre el énfasis.
  final Color onAccent;

  /// Confirmaciones ("✓ Disponible").
  final Color success;

  /// Errores y acciones que borran (no está en el prototipo).
  final Color danger;

  bool get isDark => brightness == Brightness.dark;

  /// Tinta con otra opacidad (los valores sueltos del prototipo: .78, .7…).
  Color inkA(double alpha) => ink.withValues(alpha: alpha);

  /// La misma paleta con otro color de énfasis (uno de `accentPalette`).
  /// En claro, la opción de tinta pasa a ser la tinta clara (con el fondo
  /// como texto encima) y `accentText` baja a luminosidad 0,52.
  ViniloPalette withAccent(Color accent) {
    if (isDark) return copyWith(accent: accent, accentText: accent);
    if (accent.toARGB32() == VColors.inkAccent.toARGB32()) {
      return copyWith(accent: ink, accentText: ink, onAccent: bg);
    }
    final o = Oklch.fromColor(accent);
    return copyWith(accent: accent, accentText: Oklch(0.52, o.c, o.h).toColor());
  }

  /// Cómo se ve una opción de la paleta en este tema: en claro, la de tinta
  /// es la tinta oscura (si no, sería un cuadro casi invisible).
  Color swatch(Color option) =>
      !isDark && option.toARGB32() == VColors.inkAccent.toARGB32() ? ink : option;

  /// Tono de portada para texto (nota y artista del disco, diario…): claro
  /// en oscuro y oscuro en claro.
  Color coverTone(Color cover) => coverToneFor(cover, brightness);

  /// Tono de fondo de una portada o un color (franja de lista, banner).
  Color coverShade(Color color, {double lightness = 0.31}) =>
      coverShadeFor(color, brightness, lightness: lightness);

  /// Fondo del avatar sin foto.
  Color personTone(Color color) => personToneFor(color, brightness);

  static const ViniloPalette dark = ViniloPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0F0E0D),
    sheet: Color(0xFF171615),
    surface: Color(0xFF2A2826),
    ink: Color(0xFFEFEBE4),
    ink2: Color(0x9EEFEBE4),
    ink3: Color(0x94EFEBE4),
    ink4: Color(0x80EFEBE4),
    line: Color(0x24EFEBE4),
    lineSoft: Color(0x14EFEBE4),
    lineStrong: Color(0x47EFEBE4),
    buttonLine: Color(0x2EEFEBE4),
    inactive: Color(0x8CEFEBE4),
    placeholder: Color(0x73EFEBE4),
    scrim: Color(0xB8080807),
    overButton: Color(0x8C0F0E0D),
    onAccent: Color(0xFF0F0E0D),
    success: Color(0xFF76CF8A),
    danger: Color(0xFFED756E),
  );

  /// "Modo claro" de la especificación: papel cálido y tinta casi negra.
  /// `buttonLine`, `inactive`, `placeholder`, `overButton`, `success` y
  /// `danger` no están en la tabla del diseñador: siguen las mismas
  /// opacidades que en oscuro (un poco más fuertes, como hace él con las
  /// tintas) y los colores de estado bajan de luminosidad para leerse.
  static const ViniloPalette light = ViniloPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF3EFE7),
    sheet: Color(0xFFFBF9F5),
    surface: Color(0xFFE2DDD3),
    ink: Color(0xFF161412),
    ink2: Color(0xAD161412),
    ink3: Color(0x9E161412),
    ink4: Color(0x8C161412),
    line: Color(0x24161412),
    lineSoft: Color(0x14161412),
    lineStrong: Color(0x4D161412),
    buttonLine: Color(0x33161412),
    inactive: Color(0x8C161412),
    placeholder: Color(0x80161412),
    scrim: Color(0x66161412),
    overButton: Color(0x8CF3EFE7),
    onAccent: Color(0xFF0F0E0D),
    success: Color(0xFF2E8A4A),
    danger: Color(0xFFC23F36),
  );

  @override
  ViniloPalette copyWith({
    Brightness? brightness,
    Color? accent,
    Color? accentText,
    Color? bg,
    Color? sheet,
    Color? surface,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? line,
    Color? lineSoft,
    Color? lineStrong,
    Color? buttonLine,
    Color? inactive,
    Color? placeholder,
    Color? scrim,
    Color? overButton,
    Color? onAccent,
    Color? success,
    Color? danger,
  }) {
    return ViniloPalette(
      brightness: brightness ?? this.brightness,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      bg: bg ?? this.bg,
      sheet: sheet ?? this.sheet,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      lineStrong: lineStrong ?? this.lineStrong,
      buttonLine: buttonLine ?? this.buttonLine,
      inactive: inactive ?? this.inactive,
      placeholder: placeholder ?? this.placeholder,
      scrim: scrim ?? this.scrim,
      overButton: overButton ?? this.overButton,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  ViniloPalette lerp(ThemeExtension<ViniloPalette>? other, double t) {
    if (other is! ViniloPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return ViniloPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      accent: mix(accent, other.accent),
      accentText: mix(accentText, other.accentText),
      bg: mix(bg, other.bg),
      sheet: mix(sheet, other.sheet),
      surface: mix(surface, other.surface),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      ink4: mix(ink4, other.ink4),
      line: mix(line, other.line),
      lineSoft: mix(lineSoft, other.lineSoft),
      lineStrong: mix(lineStrong, other.lineStrong),
      buttonLine: mix(buttonLine, other.buttonLine),
      inactive: mix(inactive, other.inactive),
      placeholder: mix(placeholder, other.placeholder),
      scrim: mix(scrim, other.scrim),
      overButton: mix(overButton, other.overButton),
      onAccent: mix(onAccent, other.onAccent),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
    );
  }
}

/// Acceso a la paleta del tema activo y a los colores que se pueden elegir.
class VColors {
  VColors._();

  static ViniloPalette of(BuildContext context) =>
      Theme.of(context).extension<ViniloPalette>() ?? ViniloPalette.dark;

  /// Los 14 colores de énfasis del prototipo (convertidos de OKLCH, ver
  /// `test/theme_test.dart`): tiñen la app de quien lo elige y son el color
  /// de su avatar.
  static const List<Color> accentPalette = [
    Color(0xFFFD6A3A), // oklch(0.7 0.19 38), bermellón
    Color(0xFFF66B71), // oklch(0.7 0.17 20)
    Color(0xFFE3AE28), // oklch(0.78 0.15 85)
    Color(0xFFA0C849), // oklch(0.78 0.16 125)
    Color(0xFF53BE70), // oklch(0.72 0.15 150)
    Color(0xFF2FBDA7), // oklch(0.72 0.12 180)
    Color(0xFF2FB5D8), // oklch(0.72 0.12 220)
    Color(0xFF4990E8), // oklch(0.65 0.15 255)
    Color(0xFF877FE6), // oklch(0.65 0.15 285)
    Color(0xFFBB82E3), // oklch(0.7 0.15 310)
    Color(0xFFDE73BD), // oklch(0.7 0.16 340)
    Color(0xFFE44D7D), // oklch(0.64 0.19 5)
    Color(0xFFAC713E), // oklch(0.6 0.1 60)
    inkAccent, // tinta
  ];

  /// La opción de tinta de la paleta (en claro se ve como la tinta oscura,
  /// ver `ViniloPalette.withAccent` y `swatch`).
  static const Color inkAccent = Color(0xFFEFEBE4);

  /// El color de la paleta más parecido: los perfiles guardan cualquier
  /// ARGB (los de antes del rediseño, uno de la paleta vieja) y se muestran
  /// con el más cercano de la nueva, sin migrar nada.
  static Color nearest(Color color) {
    var best = accentPalette.first;
    var bestDistance = double.infinity;
    for (final candidate in accentPalette) {
      if (candidate.toARGB32() == color.toARGB32()) return candidate;
      final d = Oklch.distance(color, candidate);
      if (d < bestDistance) {
        bestDistance = d;
        best = candidate;
      }
    }
    return best;
  }
}

/// Tipografía del rediseño. Sin `color`, el texto hereda el del tema.
/// - `display`: Archivo condensada (eje de ancho 62–80 %) para títulos,
///   notas y numerales.
/// - `ui`: Archivo de ancho normal para la interfaz.
/// - `mono`: IBM Plex Mono para etiquetas y datos (el texto en mayúsculas lo
///   pone `VMono`).
/// - `quote`: Newsreader itálica para las citas de las reseñas.
/// El interlineado se reparte arriba y abajo como en CSS; sin `height` es
/// el "normal" de la fuente, igual que en el prototipo.
class VText {
  VText._();

  static const String archivo = 'Archivo';
  static const String plexMono = 'PlexMono';
  static const String newsreader = 'Newsreader';

  /// Títulos y numerales grandes. `stretch` es el `font-stretch` del
  /// prototipo (62 a 80) y `tracking`, el espaciado en em.
  static TextStyle display(
    double size, {
    Color? color,
    double? height = 0.9,
    int weight = 800,
    double stretch = 62,
    double tracking = -0.01,
    double? letterSpacing,
  }) {
    return _archivo(
      size,
      weight: weight,
      stretch: stretch,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? tracking * size,
    );
  }

  /// Texto de interfaz (Archivo de ancho normal).
  static TextStyle ui(
    double size, {
    int weight = 400,
    Color? color,
    double? height,
    double letterSpacing = 0,
    double stretch = 100,
  }) {
    return _archivo(
      size,
      weight: weight,
      stretch: stretch,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Etiquetas y datos en IBM Plex Mono. `tracking` en em (.06–.1).
  static TextStyle mono(
    double size, {
    Color? color,
    int weight = 500,
    double tracking = 0.08,
    double? height,
  }) {
    return TextStyle(
      fontFamily: plexMono,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: tracking * size,
      fontWeight: _weight(weight),
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Citas de reseñas: Newsreader itálica 400, con el tamaño óptico que el
  /// navegador elige solo (igual al tamaño de la letra).
  static TextStyle quote(double size, {Color? color, double? height = 1.22}) {
    return TextStyle(
      fontFamily: newsreader,
      fontSize: size,
      color: color,
      height: height,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      fontVariations: [
        FontVariation('opsz', size.clamp(6, 72).toDouble()),
        const FontVariation('wght', 400),
      ],
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static TextStyle _archivo(
    double size, {
    required int weight,
    required double stretch,
    Color? color,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: archivo,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: _weight(weight),
      fontVariations: [
        FontVariation('wdth', stretch),
        FontVariation('wght', weight.toDouble()),
      ],
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static FontWeight _weight(int w) =>
      FontWeight.values[((w ~/ 100) - 1).clamp(0, 8)];
}

class VSpace {
  VSpace._();

  /// Margen lateral de las pantallas (24 en la bienvenida).
  static const double page = 20;

  /// Aire al final de las listas de las pestañas: la barra inferior ya no
  /// tapa el contenido.
  static const double tabBarClearance = 24;
}

ThemeData buildViniloTheme(ViniloPalette p) {
  final scheme = (p.isDark ? ColorScheme.dark : ColorScheme.light)(
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    surface: p.bg,
    onSurface: p.ink,
    error: p.danger,
    onError: p.onAccent,
    outline: p.lineStrong,
    outlineVariant: p.line,
    surfaceContainerHighest: p.sheet,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    fontFamily: VText.archivo,
    splashFactory: NoSplash.splashFactory,
    highlightColor: p.ink.withValues(alpha: 0.06),
    hoverColor: Colors.transparent,
  );

  const square = RoundedRectangleBorder();

  return base.copyWith(
    extensions: [p],
    textTheme: base.textTheme.apply(
      bodyColor: p.ink,
      displayColor: p.ink,
      fontFamily: VText.archivo,
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
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: square,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.sheet,
      contentTextStyle: VText.ui(14, color: p.ink),
      actionTextColor: p.accentText,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: p.line)),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accentText,
      selectionColor: p.accent.withValues(alpha: 0.33),
      selectionHandleColor: p.accentText,
    ),
    // Campos sin caja y sin borde propio: la línea de debajo (1 px, 2 px de
    // énfasis con foco) la dibuja `LineField`. Si el tema pintara otra, un
    // campo que la herede sale con dos rayas.
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      isDense: true,
      hintStyle: VText.ui(17, color: p.placeholder),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: p.surface,
        disabledForegroundColor: p.ink4,
        minimumSize: const Size.fromHeight(56),
        shape: square,
        elevation: 0,
        textStyle: VText.ui(16, weight: 600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size.fromHeight(52),
        shape: square,
        side: BorderSide(color: p.lineStrong),
        textStyle: VText.ui(16, weight: 500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.ink2,
        shape: square,
        textStyle: VText.ui(14, weight: 500),
      ),
    ),
    iconTheme: IconThemeData(color: p.ink),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    dialogTheme: DialogThemeData(
      backgroundColor: p.sheet,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: p.line)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.sheet,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: p.line)),
    ),
  );
}

/// Estilo de la barra de estado según el brillo del tema: íconos claros
/// sobre fondo oscuro y viceversa.
SystemUiOverlayStyle overlayStyleFor(Brightness brightness) =>
    brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
