import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

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

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 14,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 13,
        color: AppColors.mutedSteel,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 12,
        color: AppColors.mutedSteel,
      );
}
