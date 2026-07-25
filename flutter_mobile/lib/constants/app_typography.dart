import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _base(double size, FontWeight weight) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: AppColors.textPrimary);

  static TextStyle get displayLarge => _base(32, FontWeight.w700);
  static TextStyle get headlineLarge => _base(28, FontWeight.w700);
  static TextStyle get headlineMedium => _base(24, FontWeight.w600);
  static TextStyle get titleLarge => _base(20, FontWeight.w600);
  static TextStyle get titleMedium => _base(18, FontWeight.w600);
  static TextStyle get titleSmall => _base(16, FontWeight.w500);
  static TextStyle get bodyLarge => _base(16, FontWeight.w400);
  static TextStyle get bodyMedium => _base(14, FontWeight.w400);
  static TextStyle get bodySmall => _base(12, FontWeight.w400);
  static TextStyle get labelLarge => _base(14, FontWeight.w500);
  static TextStyle get labelMedium => _base(12, FontWeight.w500);
  static TextStyle get labelSmall => _base(10, FontWeight.w500);
}
