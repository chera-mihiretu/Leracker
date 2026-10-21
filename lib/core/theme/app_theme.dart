import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors from the progress logo palette
  static const Color emerald = Color(0xFF22C55E);
  static const Color jade = Color(0xFF10B981);
  static const Color mint = Color(0xFF86EFAC);

  // Dark palette backgrounds and surfaces (Obsidian / Slate)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkInactive = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF8FAFC); // Slate 50
  static const Color darkSubtext = Color(0xFF94A3B8); // Slate 400

  // Light palette backgrounds and surfaces
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color lightInactive = Color(0xFFE2E8F0);
  static const Color lightOnSurface = Color(0xFF0F172A); // Slate 900
  static const Color lightSubtext = Color(0xFF64748B); // Slate 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: emerald,
        onPrimary: Colors.white,
        secondary: jade,
        onSecondary: Colors.white,
        tertiary: mint,
        onTertiary: darkBackground,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightSubtext,
        surfaceContainerHighest: lightSurfaceVariant,
        outline: lightInactive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emerald,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightInactive, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightOnSurface,
          side: const BorderSide(color: lightInactive, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: emerald,
        onPrimary: darkBackground,
        secondary: jade,
        onSecondary: darkBackground,
        tertiary: mint,
        onTertiary: darkBackground,
        error: Color(0xFFF87171),
        onError: darkBackground,
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkSubtext,
        surfaceContainerHighest: darkSurfaceVariant,
        outline: darkInactive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emerald,
        foregroundColor: darkBackground,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkInactive, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOnSurface,
          side: const BorderSide(color: darkInactive, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
