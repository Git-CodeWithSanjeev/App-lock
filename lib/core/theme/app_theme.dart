import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Minimal Samsung One UI–inspired Design System.
class AppTheme {
  // Aliases referencing AppColors directly for backward compatibility
  static const Color surface = AppColors.surface;
  static const Color surfaceDim = AppColors.surfaceDim;
  static const Color surfaceBright = AppColors.surfaceBright;
  static const Color surfaceContainerLowest = AppColors.surfaceContainerLowest;
  static const Color surfaceContainerLow = AppColors.surfaceContainerLow;
  static const Color surfaceContainer = AppColors.surfaceContainer;
  static const Color surfaceContainerHigh = AppColors.surfaceContainerHigh;
  static const Color surfaceContainerHighest = AppColors.surfaceContainerHighest;

  static const Color onSurface = AppColors.onSurface;
  static const Color onSurfaceVariant = AppColors.onSurfaceVariant;
  static const Color slateText = AppColors.slateText;
  static const Color mutedSteel = AppColors.mutedSteel;
  static const Color mutedLight = AppColors.mutedLight;

  static const Color outline = AppColors.outline;
  static const Color outlineVariant = AppColors.outlineVariant;
  static const Color outlineLight = AppColors.outlineLight;

  static const Color primary = AppColors.primary;
  static const Color primaryContainer = AppColors.primaryContainer;
  static const Color onPrimary = AppColors.onPrimary;
  static const Color onPrimaryContainer = AppColors.onPrimaryContainer;
  static const Color blueBg = AppColors.blueBg;
  static const Color blueBorder = AppColors.blueBorder;

  static const Color emeraldBg = AppColors.emeraldBg;
  static const Color emeraldBorder = AppColors.emeraldBorder;
  static const Color mintVitality = AppColors.mintVitality;

  static const Color secondary = AppColors.secondary;
  static const Color secondaryContainer = AppColors.secondaryContainer;
  static const Color onSecondaryContainer = AppColors.onSecondaryContainer;
  static const Color knoxBadgeColor = AppColors.knoxBadgeColor;

  static const Color error = AppColors.error;
  static const Color errorContainer = AppColors.errorContainer;
  static const Color warningAmber = AppColors.warningAmber;

  // Subtle One UI Elevation Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(10),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadowLifted => [
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(18),
          blurRadius: 18,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      ];

  // One UI Rounded Card Decoration
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 24,
    bool lifted = false,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? surfaceContainerLowest,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? outlineVariant,
        width: 1,
      ),
      boxShadow: lifted ? cardShadowLifted : cardShadow,
    );
  }

  // Squircle Icon Badge Box Decoration
  static BoxDecoration squircleIconDecoration({
    Color? bgColor,
    Color? borderColor,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: bgColor ?? blueBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? blueBorder,
        width: 1,
      ),
    );
  }

  // Theme Data Setup with Clean One UI Typography
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        surface: surface,
        surfaceContainerLowest: surfaceContainerLowest,
        error: error,
        onPrimary: onPrimary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.displayLarge,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
