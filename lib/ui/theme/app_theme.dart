import 'package:flutter/material.dart';
import 'tokens.dart';

/// Makes the token set reachable from any BuildContext.
@immutable
class PianoColorsExtension extends ThemeExtension<PianoColorsExtension> {
  const PianoColorsExtension(this.colors);

  final PianoColors colors;

  @override
  PianoColorsExtension copyWith({PianoColors? colors}) =>
      PianoColorsExtension(colors ?? this.colors);

  @override
  PianoColorsExtension lerp(
      ThemeExtension<PianoColorsExtension>? other, double t) {
    if (other is! PianoColorsExtension) return this;
    final a = colors.argb;
    final b = other.colors.argb;
    return PianoColorsExtension(PianoColors.fromArgb({
      for (final key in a.keys)
        key: Color.lerp(Color(a[key]!), Color(b[key]!), t)!.toARGB32(),
    }));
  }
}

abstract final class PianoTheme {
  static ThemeData light() => _build(PianoColors.light(), Brightness.light);
  static ThemeData dark() => _build(PianoColors.dark(), Brightness.dark);

  static PianoColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<PianoColorsExtension>()!.colors;

  static TextTheme textThemeOf(BuildContext context) =>
      Theme.of(context).textTheme;

  static ThemeData _build(PianoColors c, Brightness brightness) {
    // Display is Cormorant, roman only. Body and every metric is Plex Sans.
    //
    // Both faces are variable fonts registered with no weight entries in
    // pubspec, so `fontWeight` alone would not move the axis — it would let
    // the engine synthesise a fake bold. `fontVariations` drives the real
    // 'wght' axis; `fontWeight` stays alongside it so weight-aware widgets
    // and any fallback face still behave.
    TextStyle display(double size, int weight, double height) => TextStyle(
          fontFamily: 'CormorantGaramond',
          fontWeight: FontWeight.values.firstWhere((w) => w.value == weight),
          fontVariations: [FontVariation('wght', weight.toDouble())],
          fontSize: size,
          height: height,
          color: c.ink,
        );

    TextStyle body(double size, int weight, double height, Color color,
            {bool tabular = false}) =>
        TextStyle(
          fontFamily: 'IBMPlexSans',
          fontWeight: FontWeight.values.firstWhere((w) => w.value == weight),
          fontVariations: [FontVariation('wght', weight.toDouble())],
          fontSize: size,
          height: height,
          color: color,
          fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        );

    final text = TextTheme(
      displayLarge: display(44, 700, 1.08),
      headlineLarge: display(32, 700, 1.12),
      headlineSmall: display(22, 600, 1.15),
      titleLarge: display(20, 600, 1.2),
      bodyLarge: body(16, 400, 1.55, c.ink),
      bodyMedium: body(14, 400, 1.5, c.ink2),
      bodySmall: body(12, 400, 1.45, c.muted),
      // labelLarge is the metric role: anything numeric that changes.
      labelLarge: body(13, 600, 1.2, c.ink, tabular: true),
      labelSmall: body(11, 500, 1.2, c.muted, tabular: true),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      dividerColor: c.rule,
      textTheme: text,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.accentInk,
        secondary: c.accent,
        onSecondary: c.accentInk,
        error: c.error,
        onError: c.paper,
        surface: c.paper,
        onSurface: c.ink,
        surfaceContainerHighest: c.paper3,
        outline: c.rule,
      ),
      // Depth is weight and lightness, never shadow.
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: c.paper2,
          foregroundColor: c.ink),
      dividerTheme: DividerThemeData(color: c.rule, thickness: 1, space: 1),
      extensions: [PianoColorsExtension(c)],
    );
  }
}
