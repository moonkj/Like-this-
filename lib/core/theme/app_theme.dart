import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_dimensions.dart';

/// Like This 테마 — Dark Mode Only (Light Mode 미지원)
final class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.silver,
      onPrimary: AppColors.background,
      secondary: AppColors.silverLight,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.white,
    ),

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.h2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ── Text ──────────────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      headlineLarge:  AppTypography.h1,
      headlineMedium: AppTypography.h2,
      headlineSmall:  AppTypography.h3,
      bodyLarge:      AppTypography.body,
      bodyMedium:     AppTypography.bodySmall,
      bodySmall:      AppTypography.caption,
      labelLarge:     AppTypography.button,
      labelMedium:    AppTypography.buttonSmall,
    ),

    // ── Slider ────────────────────────────────────────────────────────────────
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.silver,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.white,
      overlayColor: AppColors.silver.withValues(alpha: 0.2),
      trackHeight: AppDimensions.sliderTrackHeight,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: AppDimensions.sliderThumbRadius,
      ),
    ),

    // ── Bottom Navigation ─────────────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.silver,
      unselectedItemColor: AppColors.textDisabled,
      type: BottomNavigationBarType.fixed,
    ),

    // ── Card ──────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    // ── Icon ──────────────────────────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppDimensions.iconSize,
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── PageTransitions ───────────────────────────────────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
