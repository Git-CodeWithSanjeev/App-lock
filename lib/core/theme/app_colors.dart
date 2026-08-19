import 'package:flutter/material.dart';

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
  static const Color secondary = Color(0xFF565E71);
  static const Color secondaryContainer = Color(0xFFDAE2F9);
  static const Color onSecondaryContainer = Color(0xFF3E4759);
  static const Color knoxBadgeColor = Color(0xFF1E6BFF);

  // Semantic Alerts
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color warningAmber = Color(0xFFE67E22);
}
