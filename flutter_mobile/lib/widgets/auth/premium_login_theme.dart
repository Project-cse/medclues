import 'package:flutter/material.dart';

/// 2026 corporate healthcare login — Practo / Apple Health tier tokens.
abstract final class PremiumLoginTheme {
  static const Color primaryBlue = Color(0xFF003B8E);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF6F9FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color avatarBg = Color(0xFFDBEAFE);
  static const Color placeholder = Color(0xFF9CA3AF);
  static const Color blobSoft = Color(0xFFDCE8FA);
  static const Color blobAccent = Color(0xFFC5D9F5);

  static const double cardRadius = 24;
  static const double fieldRadius = 16;
  static const double buttonRadius = 18;
  static const double fieldHeight = 58;
  static const double buttonHeight = 60;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  static const LinearGradient signInGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF003B8E), Color(0xFF002654)],
  );

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get buttonLoadingGlow => [
        BoxShadow(
          color: accentBlue.withValues(alpha: 0.38),
          blurRadius: 18,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];
}
