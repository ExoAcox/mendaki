import 'package:flutter/material.dart';

class AppTheme {
  // Stitch Material Theme Colors
  static const Color primary = Color(0xFF0F5238);
  static const Color primaryContainer = Color(0xFF2D6A4F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA8E7C5);

  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainer = Color(0xFFE7EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE8FF);

  static const Color onSurface = Color(0xFF111C2D);
  static const Color onSurfaceVariant = Color(0xFF404943);
  static const Color outline = Color(0xFF707973);
  static const Color outlineVariant = Color(0xFFBFC9C1);

  static const Color secondary = Color(0xFFA33D23);
  static const Color secondaryContainer = Color(0xFFFF8162);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF005236);
  static const Color tertiaryFixed = Color(0xFF92F7C3);
  static const Color tertiaryFixedDim = Color(0xFF75DAA8);

  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: Color(0xFF731A04),
        tertiary: tertiary,
        onTertiary: Color(0xFFFFFFFF),
        error: error,
        onError: Color(0xFFFFFFFF),
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

