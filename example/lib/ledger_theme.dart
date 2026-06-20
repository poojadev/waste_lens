import 'package:flutter/material.dart';

/// "Evidence Ledger" design tokens. Each colour maps to a verdict, not a mood:
/// amber = waste caught, red = severe/leak, sage = cleared.
abstract final class Ledger {
  static const Color ink = Color(0xFF16140F); // warmed graphite base
  static const Color inkRaised = Color(0xFF211E17); // card surface
  static const Color paper = Color(0xFFE8E1D0); // aged-paper foreground
  static const Color charge = Color(0xFFE0A52E); // evidence amber
  static const Color verdict = Color(0xFFC8442E); // leaks / severe
  static const Color cleared = Color(0xFF5FA67A); // healthy
  static const Color mark = Color(0xFF7C5CFF); // wordmark only
  static const Color hairline = Color(0x22E8E1D0);

  // IBM Plex Mono is the ledger's "data voice"; falls back to the platform
  // monospace when the font isn't bundled.
  static const String mono = 'monospace';

  static TextStyle get eyebrow => const TextStyle(
        fontFamily: mono,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: charge,
      );

  static TextStyle get title => const TextStyle(
        fontSize: 22,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: paper,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14,
        height: 1.4,
        color: paper.withValues(alpha: 0.78),
      );

  static TextStyle get data => const TextStyle(
        fontFamily: mono,
        fontSize: 13,
        color: paper,
      );

  static ThemeData themeData() {
    const scheme = ColorScheme.dark(
      primary: charge,
      secondary: cleared,
      error: verdict,
      surface: inkRaised,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      fontFamily: 'IBM Plex Sans',
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: paper,
        displayColor: paper,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: paper,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
