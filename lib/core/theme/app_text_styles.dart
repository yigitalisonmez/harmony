import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Jost — headings
  static final appTitle = GoogleFonts.jost(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.foreground,
    letterSpacing: -1.0,
  );

  // Figtree — body
  static final body = GoogleFonts.figtree(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
  );

  static final bodyBold = GoogleFonts.figtree(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
  );

  static final label = GoogleFonts.figtree(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.foreground,
    letterSpacing: 2.0,
  );

  static final badgeText = GoogleFonts.figtree(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.foreground,
    letterSpacing: 1.5,
  );

  // Playfair Display — serif notes
  static final noteText = GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.foreground,
    height: 1.6,
    letterSpacing: -0.2,
  );

  // Muted variants
  static final muted = GoogleFonts.figtree(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.mutedForeground,
    letterSpacing: 2.0,
  );
}
