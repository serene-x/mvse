import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const warmWhite = Color(0xFFFAF6F2);
  static const surface   = Color(0xFFFFFFFF);
  static const beige     = Color(0xFFF1E5DA);
  static const beigeDeep = Color(0xFFE3D1C1);
  static const rose      = Color(0xFFC4928E);
  static const roseDeep  = Color(0xFF9F6E6A);
  static const text      = Color(0xFF3A2E2A);
  static const textMuted = Color(0xFF8A7C76);
  static const stroke    = Color(0xFFEADFD5);
  static const positive  = Color(0xFF7FA37A);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.rose,
      onPrimary: Colors.white,
      secondary: AppPalette.beigeDeep,
      onSecondary: AppPalette.text,
      error: const Color(0xFFB7445A),
      onError: Colors.white,
      surface: AppPalette.surface,
      onSurface: AppPalette.text,
    ),
    scaffoldBackgroundColor: AppPalette.warmWhite,
    dividerColor: AppPalette.stroke,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppPalette.text,
      displayColor: AppPalette.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.warmWhite,
      foregroundColor: AppPalette.text,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.rose,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.text,
        side: const BorderSide(color: AppPalette.stroke),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.rose, width: 1.4),
      ),
    ),
    cardTheme: CardTheme(
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppPalette.stroke),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppPalette.beige,
      selectedColor: AppPalette.rose,
      labelStyle: const TextStyle(color: AppPalette.text, fontWeight: FontWeight.w500),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
  );
}
