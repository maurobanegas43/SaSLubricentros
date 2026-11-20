import 'package:flutter/material.dart';

class AppTheme {
  // Modern Industrial Color Scheme
  static const Color _lightBackground = Color(0xFFF4F7F6);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightPrimary = Color(0xFFE63946);
  static const Color _lightSecondary = Color(0xFF457B9D);
  static const Color _lightTextPrimary = Color(0xFF1D3557);
  static const Color _lightTextSecondary = Color(0xFF6D6D6D);

  static const Color _darkBackground = Color(0xFF0F111A);
  static const Color _darkSurface = Color(0xFF1B1F2D);
  static const Color _darkPrimary = Color(0xFFFF4D5A); // Brighter red for dark mode contrast
  static const Color _darkSecondary = Color(0xFFA8DADC);
  static const Color _darkTextPrimary = Color(0xFFF1FAEE);
  static const Color _darkTextSecondary = Color(0xFFB0BEC5); // Improved contrast

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      surface: _lightBackground,
      primary: _lightPrimary,
      secondary: _lightSecondary,
      onSurface: _lightTextPrimary,
      onPrimary: Colors.white,
      error: Color(0xFFD32F2F),
    ),
    scaffoldBackgroundColor: _lightBackground,

    // Typography - Material 3 scale
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        letterSpacing: -0.5, color: _lightTextPrimary, height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600,
        letterSpacing: -0.3, color: _lightTextPrimary, height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: _lightTextPrimary, height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: _lightTextPrimary, height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: _lightTextPrimary, height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: _lightTextPrimary, height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: _lightTextSecondary, height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: 0.1, color: _lightTextPrimary,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: _lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withValues(alpha: 0.05),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: _darkBackground,
      primary: _darkPrimary,
      secondary: _darkSecondary,
      onSurface: _darkTextPrimary,
      onPrimary: Colors.white,
      error: Color(0xFFEF5350), // Brighter error for dark mode
    ),
    scaffoldBackgroundColor: _darkBackground,

    // Typography - Material 3 scale
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        letterSpacing: -0.5, color: _darkTextPrimary, height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600,
        letterSpacing: -0.3, color: _darkTextPrimary, height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: _darkTextPrimary, height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: _darkTextPrimary, height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: _darkTextPrimary, height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: _darkTextPrimary, height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: _darkTextSecondary, height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: 0.1, color: _darkTextPrimary,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2D3748), width: 1),
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D3748)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D3748)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
