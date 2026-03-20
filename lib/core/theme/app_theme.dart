/// Material 3 theme configuration matching Sandalan web app.
/// Uses neutral base with muted green primary (oklch(0.55 0.14 155)).

import 'package:flutter/material.dart';

class AppTheme {
  // Web app primary green: oklch(0.55 0.14 155) ≈ #2D8B5E
  static const _primaryColor = Color(0xFF2D8B5E);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: const Color(0xFFF8FAF9),
      surface: const Color(0xFFFBFDFC),
      onSurface: const Color(0xFF1A2E23),
      surfaceContainerHighest: const Color(0xFFF0F4F2),
      outline: const Color(0xFFD1D9D4),
      error: const Color(0xFFDC2626),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFBFDFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A2E23),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A2E23)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF1A2E23).withValues(alpha: 0.08)),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFFD1D9D4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFFD1D9D4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: const Color(0xFF1A2E23).withValues(alpha: 0.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: const Color(0xFFF8FAF9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A2E23),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: const Color(0xFFD1D9D4)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: const Color(0xFFA3A3A3),
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF1A2E23).withValues(alpha: 0.08),
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static ThemeData dark() {
    // ── Web dark-mode palette (oklch values from globals.css) ──
    // --background:         oklch(0.14 0.015 160) ≈ #0A1410
    // --foreground:         oklch(0.97 0.005 155) ≈ #F3F6F4
    // --card:               oklch(0.19 0.015 160) ≈ #111A15
    // --popover:            oklch(0.22 0.015 160) ≈ #151D18
    // --primary:            oklch(0.65 0.16  155) ≈ #3DB676 (gamut-mapped)
    // --primary-foreground: oklch(0.12 0.02  160) ≈ #040E08
    // --secondary/muted:    oklch(0.24 0.02  160) ≈ #17221C
    // --muted-foreground:   oklch(0.65 0.015 155) ≈ #8A948D
    // --accent:             oklch(0.30 0.03  155) ≈ #223227
    // --destructive:        oklch(0.704 0.191 22)  ≈ #FF6467
    // --border:             oklch(1 0 0 / 10%)     = white @ 10%
    // --input:              oklch(1 0 0 / 15%)     = white @ 15%

    const darkPrimary = Color(0xFF3DB676);

    // Web CSS variable -> Flutter ColorScheme mapping
    const background    = Color(0xFF0A1410); // --background
    const foreground    = Color(0xFFF3F6F4); // --foreground
    const card          = Color(0xFF111A15); // --card
    const popover       = Color(0xFF151D18); // --popover
    const primaryFg     = Color(0xFF040E08); // --primary-foreground
    const secondary     = Color(0xFF17221C); // --secondary / --muted
    const mutedFg       = Color(0xFF8A948D); // --muted-foreground
    const accent        = Color(0xFF223227); // --accent
    const destructive   = Color(0xFFFF6467); // --destructive

    final colorScheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: primaryFg,
      surface: background,
      onSurface: foreground,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: popover,
      surfaceContainerHighest: secondary,
      outline: Colors.white.withValues(alpha: 0.10),
      outlineVariant: Colors.white.withValues(alpha: 0.06),
      secondary: accent,
      onSecondary: foreground,
      tertiary: mutedFg,
      error: destructive,
      onError: foreground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: foreground),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        color: card,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: mutedFg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: primaryFg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkPrimary,
        unselectedItemColor: mutedFg,
        backgroundColor: background,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.10),
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: popover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: popover,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}
