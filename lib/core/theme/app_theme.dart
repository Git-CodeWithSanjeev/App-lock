import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic color tokens for the Porcelain Guardian One UI design system.
class AppColors {
  // Surface & Background Colors
  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceDim = Color(0xFFE8EAEE);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF1F5);
  static const Color surfaceContainer = Color(0xFFE8EBF0);
  static const Color surfaceContainerHigh = Color(0xFFE2E5EB);
  static const Color surfaceContainerHighest = Color(0xFFDCE0E7);

  // Text & On-Surface Colors
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color slateText = Color(0xFF1C1B1F);
  static const Color mutedSteel = Color(0xFF74777F);
  static const Color mutedLight = Color(0xFF9397A1);

  // Structural Outlines & Dividers
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFECEEF2);
  static const Color outlineLight = Color(0xFFE0E2E8);

  // One UI Royal Blue & Accents
  static const Color primary = Color(0xFF1E6BFF);
  static const Color primaryContainer = Color(0xFF1E6BFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color blueBg = Color(0xFFEFF4FF);
  static const Color blueBorder = Color(0xFFD3E2FF);

  // Aliases for system styling
  static const Color emeraldBg = blueBg;
  static const Color emeraldBorder = blueBorder;
  static const Color mintVitality = primary;

  // Secondary & Badge Colors
  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryContainer = Color(0xFF1E293B);
  static const Color onSecondaryContainer = Color(0xFFF8FAFC);
  static const Color knoxBadgeColor = Color(0xFF1E6BFF);

  // Status & Feedback Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color warningAmber = Color(0xFFD97706);
}

/// Centralized Manrope typography styles for Porcelain Guardian UI.
class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.manrope(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -0.6,
  );

  static TextStyle get headlineLarge => GoogleFonts.manrope(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -0.4,
  );

  static TextStyle get headlineMedium => GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -0.2,
  );

  static TextStyle get titleLarge => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static TextStyle get titleMedium => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle get bodyLarge =>
      GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurface);

  static TextStyle get bodyMedium =>
      GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedSteel);

  static TextStyle get caption =>
      GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedSteel);
}

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
  static const Color surfaceContainerHighest =
      AppColors.surfaceContainerHighest;

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
      border: Border.all(color: borderColor ?? outlineVariant, width: 1),
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
      border: Border.all(color: borderColor ?? blueBorder, width: 1),
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
