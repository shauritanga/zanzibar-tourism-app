// File: lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB57F50), // Warm spice tone
      primary: const Color(0xFFB57F50), // Sand/spice
      secondary: const Color(0xFF4A90A4), // Ocean blue
      surface: const Color(0xFFFFF8E1), // Light warm background
      onSurface: const Color(0xFF4E342E), // Earthy brown
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF3E0), // Coastal light tone
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFB57F50),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFF4E342E), // Earthy brown
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF5D4037), // Brown for text
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
      ),
    ),
    useMaterial3: true,
  );

  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB57F50),
      primary: const Color(0xFFB57F50),
      secondary: const Color(0xFF4A90A4),
      surface: const Color(0xFF212121), // Dark surface
      background: const Color(0xFF303030), // Dark background
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF303030), // Dark background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFB57F50),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Colors.white, // Light text for dark theme
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: Colors.white, // Light text for dark theme
      ),
      bodyLarge: TextStyle(
        color: Colors.white, // Light text for dark theme
      ),
      bodySmall: TextStyle(
        color: Colors.white, // Light text for dark theme
      ),
      titleLarge: TextStyle(
        color: Colors.white, // Light text for dark theme
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.white, // Light text for dark theme
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
      ),
    ),
  );
}
