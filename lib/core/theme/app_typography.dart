import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme createTextTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      // Display & Headlines: Quicksand (Bold / Semi-bold)
      displayLarge: GoogleFonts.quicksand(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: onSurface,
      ),

      // Titles & Body: Inter (Semi-bold, Medium, Regular)
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: onSurface,
      ),

      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: onSurfaceVariant,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: onSurfaceVariant,
      ),

      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.01 * 14,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
        color: onSurfaceVariant,
      ),
    );
  }
}
