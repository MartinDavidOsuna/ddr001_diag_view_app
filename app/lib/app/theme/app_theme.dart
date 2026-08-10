import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0F1826);
  static const panel = Color(0xFF17263A);
  static const panelDark = Color(0xFF0F1C2C);
  static const panelLight = Color(0xFF1F3247);
  static const line = Color(0xFF2B425C);
  static const navy = Color(0xFF1F3B5C);
  static const blue = Color(0xFF1F5C99);
  static const green = Color(0xFF1E7E45);
  static const red = Color(0xFFB03A2E);
  static const amber = Color(0xFFC07B1F);
  static const text = Color(0xFFE8EEF5);
  static const muted = Color(0xFF9FB2C8);
  static const heading = Color(0xFF8FB4DD);
  static const success = Color(0xFF54D98C);
  static const danger = Color(0xFFFF7A6B);
  static const warning = Color(0xFFFFBF5E);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

abstract final class AppRadius {
  static const field = 9.0;
  static const card = 12.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.blue,
      secondary: AppColors.amber,
      surface: AppColors.panel,
      error: AppColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
      fontFamily: 'Roboto',
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panelDark,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.panelLight,
      contentTextStyle: TextStyle(color: AppColors.text),
    ),
  );
}
