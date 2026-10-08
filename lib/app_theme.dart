import 'package:flutter/material.dart';

class AppTheme {
  // =========================
  // COLORS
  // =========================

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF9F7);

  static const Color black = Color(0xFF1C1B1A);
  static const Color textSecondary = Color(0xFF6F6A66);

  static const Color darkBrown = Color(0xFF5A3825);
  static const Color brown = Color(0xFF79533B);
  static const Color lightBrown = Color(0xFFE8DDD5);

  static const Color softGray = Color(0xFFF3F1EF);
  static const Color border = Color(0xFFE4E0DC);

  static const Color error = Color(0xFFB3261E);

  // =========================
  // RADIUS
  // =========================

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // =========================
  // THEME
  // =========================

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brown,
      brightness: Brightness.light,
    ).copyWith(
      primary: darkBrown,
      secondary: brown,
      surface: white,
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: black,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: background,

      // =========================
      // FONT
      // =========================

      fontFamily: 'Manrope',

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: black,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: black,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),

      // =========================
      // APP BAR
      // =========================

      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // =========================
      // CARDS
      // =========================

      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),

      // =========================
      // INPUTS
      // =========================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        hintStyle: const TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w400,
        ),

        labelStyle: const TextStyle(
          color: textSecondary,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: brown,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: error,
            width: 1.5,
          ),
        ),
      ),

      // =========================
      // PRIMARY BUTTON
      // =========================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBrown,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =========================
      // OUTLINED BUTTON
      // =========================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          backgroundColor: white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          side: const BorderSide(
            color: border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =========================
      // TEXT BUTTON
      // =========================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkBrown,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =========================
      // FLOATING BUTTON
      // =========================

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkBrown,
        foregroundColor: white,
        elevation: 1,
      ),

      // =========================
      // DIVIDERS
      // =========================

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // =========================
      // DIALOGS
      // =========================

      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // =========================
      // SNACKBAR
      // =========================

      snackBarTheme: SnackBarThemeData(
        backgroundColor: black,
        contentTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // =========================
      // ICONS
      // =========================

      iconTheme: const IconThemeData(
        color: black,
        size: 21,
      ),
    );
  }
}
