import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/core/configs/theme/app_text_styles.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    brightness: Brightness.light,
    fontFamily: AppTextStyles.fontFamily,

    textTheme: _buildTextTheme(Brightness.light),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(30),
      hintStyle: AppTextStyles.hint.copyWith(color: AppColors.lightGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.white, width: 0.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black, width: 0.4),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        elevation: 0,
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    brightness: Brightness.dark,
    fontFamily: AppTextStyles.fontFamily,

    textTheme: _buildTextTheme(Brightness.dark),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(30),
      hintStyle: AppTextStyles.hint.copyWith(color: AppColors.lightGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.white, width: 0.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.white, width: 0.4),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        elevation: 0,
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
  );

  // ── TextTheme đầy đủ theo Material 3 naming ─────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final defaultColor = isLight ? const Color(0xFF1A1A1A) : Colors.white;
    final subtleColor = isLight ? const Color(0xFF6B7280) : const Color(0xFFB0B0B0);

    return TextTheme(
      displayLarge: AppTextStyles.h1.copyWith(color: defaultColor),
      displayMedium: AppTextStyles.h2.copyWith(color: defaultColor),
      displaySmall: AppTextStyles.h3.copyWith(color: defaultColor),
      headlineLarge: AppTextStyles.h3.copyWith(color: defaultColor),
      headlineMedium: AppTextStyles.h4.copyWith(color: defaultColor),
      headlineSmall: AppTextStyles.h5.copyWith(color: defaultColor),
      titleLarge: AppTextStyles.h4.copyWith(color: defaultColor),
      titleMedium: AppTextStyles.h5.copyWith(color: defaultColor),
      titleSmall: AppTextStyles.h6.copyWith(color: defaultColor),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: defaultColor),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: defaultColor),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: subtleColor),
      labelLarge: AppTextStyles.labelMedium.copyWith(color: defaultColor),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: subtleColor),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: subtleColor),
    );
  }
}