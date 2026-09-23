import 'package:flutter/material.dart';

class AppPalette {
  static const warmWhite = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const beige = Color(0xFFF0EAE7);
  static const beigeDeep = Color(0xFFDFCED0);
  static const rose = Color(0xFF702D40);
  static const roseDeep = Color(0xFF512130);
  static const text = Color(0xFF242125);
  static const textMuted = Color(0xFF736B70);
  static const stroke = Color(0xFFDDD6D6);
  static const positive = Color(0xFF526B4C);
}

const editorialTitle = TextStyle(
    fontFamily: 'Arial',
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.08);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Arial',
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.rose,
        primary: AppPalette.rose,
        surface: AppPalette.surface,
        onSurface: AppPalette.text),
    scaffoldBackgroundColor: AppPalette.warmWhite,
    dividerColor: AppPalette.stroke,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppPalette.text, displayColor: AppPalette.text),
    appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.warmWhite,
        foregroundColor: AppPalette.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppPalette.rose,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.text,
            side: const BorderSide(color: AppPalette.stroke),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppPalette.stroke)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppPalette.stroke)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppPalette.rose))),
    cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppPalette.stroke))),
    chipTheme: ChipThemeData(
        backgroundColor: AppPalette.beige,
        selectedColor: AppPalette.beigeDeep,
        labelStyle: const TextStyle(color: AppPalette.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide.none),
  );
}
