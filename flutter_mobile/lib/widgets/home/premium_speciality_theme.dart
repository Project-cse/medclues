import 'package:flutter/material.dart';

/// Premium healthcare specialty grid tokens — Apple Health / Practo tier.
abstract final class PremiumSpecialityTheme {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color text = Color(0xFF1F2937);
  static const Color iconBg = Color(0xFFEAF4FF);
  static const Color selectedBg = Color(0xFFF0F7FF);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static const double cardRadius = 18;
  static const double iconSize = 56;
  static const double gridGap = 16;
  static const double horizontalMargin = 16;
  static const double cardPadding = 12;
  static const double labelHeight = 32;

  static const Duration selectionDuration = Duration(milliseconds: 200);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get selectedGlow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.22),
          blurRadius: 14,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
