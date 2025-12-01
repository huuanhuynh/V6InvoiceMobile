import 'package:flutter/material.dart';
//import 'app_configs.dart';

class AppColors {
  // Brand palette
  static const Color primary = Color(0xFF064789); // #064789
  static const Color secondary = Color(0xFF427AA1); // #427AA1
  static const Color surfaceLight = Color(0xFFEBF2FA); // #EBF2FA
  static const Color bottomTabsBackground = Color.fromARGB(
    255,
    222,
    231,
    241,
  ); // #EBF2FA

  // Text
  static const Color text = Colors.black; // Primary text should be black
  static const Color onPrimary = Colors.white;

  // Semantic (optional helpers)
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color danger = Color(0xFFD32F2F);

  // Borders and subtle fills derived from palette
  static Color get border => secondary.withAlpha(89);
  static Color get fill => surfaceLight; // for input backgrounds / cards
}

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          secondary: AppColors.secondary,
          surface: AppColors.surfaceLight,
        ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.text),
      titleLarge: TextStyle(
        color: AppColors.text,
        fontSize: 20, // app config
        fontWeight: FontWeight.bold, // app confi
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.secondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.secondary.withAlpha(89),
        disabledForegroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.secondary.withAlpha(38),
      labelStyle: const TextStyle(color: AppColors.text),
      secondaryLabelStyle: const TextStyle(color: AppColors.text),
      side: BorderSide(color: AppColors.border),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
