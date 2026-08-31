import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/core/configs/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static final lightTheme = _buildTheme(Brightness.light);
  static final darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final background =
        isLight ? AppColors.lightBackground : AppColors.darkBackground;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: surface,
      ),
      textTheme: _buildTextTheme(brightness),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: isLight ? AppColors.lightText : AppColors.darkText,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: isLight ? const Color(0xFFECEAF1) : const Color(0xFF34313F),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isLight ? const Color(0xFF252337) : const Color(0xFFF2EEFF),
        contentTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: isLight ? Colors.white : AppColors.lightText,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTextStyles.button,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  // ── TextTheme đầy đủ theo Material 3 naming ─────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final defaultColor = isLight ? AppColors.lightText : AppColors.darkText;
    final subtleColor = isLight ? AppColors.muted : const Color(0xFFAAA7B8);

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
