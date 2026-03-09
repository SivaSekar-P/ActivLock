import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // Professional iOS-inspired Colors
  static const Color mySystemBlue = Color(0xFF007AFF);
  static const Color mySystemPurple = Color(0xFFAF52DE);
  static const Color mySystemRed = Color(0xFFFF3B30);
  static const Color mySystemGreen = Color(0xFF34C759);
  
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF2F2F7); // iOS group table background
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E); // iOS elevated dark surface
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFEBEBF5); // slightly transparent white

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: mySystemBlue,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: mySystemBlue,
        secondary: mySystemPurple,
        surface: lightSurface,
        error: mySystemRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mySystemBlue),
        titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      ),
      fontFamily: 'Roboto', // System default fallback
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: mySystemBlue,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: mySystemBlue,
        secondary: mySystemPurple,
        surface: darkSurface,
        error: mySystemRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mySystemBlue),
        titleTextStyle: TextStyle(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      ),
      fontFamily: 'Roboto',
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Abstract modern gradient background
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                const Color(0xFF0F0F1A), // deep dark blue/purple tint
                const Color(0xFF000000), 
                const Color(0xFF1A1A24),
              ] 
            : [
                const Color(0xFFF2F2F7),
                const Color(0xFFE5E5EB),
              ],
        ),
      ),
      child: child,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(20.0),
    this.blur = 30.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine iOS glass properties based on theme
    final glassColor = isDark 
        ? Colors.white.withOpacity(0.08) 
        : Colors.white.withOpacity(0.5);
        
    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.white.withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? defaultBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ]
          ),
          child: child,
        ),
      ),
    );
  }
}
