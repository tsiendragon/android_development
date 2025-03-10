import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFFE57373),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE57373),
      primary: const Color(0xFFE57373),
      secondary: const Color(0xFFFFB74D),
      surface: const Color(0xFFFFF3E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF3E0),
    fontFamily: 'NotoSansSC',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
      displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
      displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
      headlineMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
      bodyLarge: TextStyle(fontSize: 16.0, color: Color(0xFF424242)),
      bodyMedium: TextStyle(fontSize: 14.0, color: Color(0xFF424242)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE57373),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
