import 'package:flutter/material.dart';

class WakandaTheme {
  // Vibranium Silver
  static const Color vibranium = Color(0xFFE0E0E0);
  static const Color vibraniumDark = Color(0xFFB0B0B0);

  // Wakanda Black/Grey
  static const Color blackMetal = Color(0xFF1A1A1A);
  static const Color onyx = Color(0xFF121212);

  // Heart-Shaped Herb Purple
  static const Color herbPurple = Color(0xFF7B1FA2);
  static const Color herbLight = Color(0xFF9C27B0);

  // Accent beads/patterns
  static const Color beadRed = Color(0xFFD32F2F);
  static const Color beadOrange = Color(0xFFFF6F00);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: onyx,
      primaryColor: herbPurple,
      colorScheme: const ColorScheme.dark(
        primary: herbPurple,
        secondary: vibranium,
        surface: blackMetal,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: vibranium,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: blackMetal,
        foregroundColor: vibranium,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
          color: vibranium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: herbPurple,
          foregroundColor: vibranium,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
      // FIXED: Used CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: blackMetal,
        elevation: 4,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: vibraniumDark, width: 0.5),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: herbPurple,
      colorScheme: const ColorScheme.light(
        primary: herbPurple,
        secondary: blackMetal,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: blackMetal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: blackMetal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
          color: blackMetal,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: herbPurple,
          foregroundColor: Colors.white,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}