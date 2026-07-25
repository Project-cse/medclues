import 'package:flutter/material.dart';

/// MedClues brand palette (navy / teal / blue) used across Flutter screens.
class AppColors {
  AppColors._();

  // Brand — MedClues
  static const Color medcluesNavy = Color(0xFF002855);
  static const Color medcluesTeal = Color(0xFF009F93);
  static const Color medcluesTealLight = Color(0xFFE0F7F5);
  static const Color brandBlue = Color(0xFF1565C0);
  static const Color brandBlueDark = Color(0xFF0D47A1);
  static const Color brandBlueLight = Color(0xFFE3F2FD);
  static const Color brandCyan = Color(0xFF57D2E8);
  static const Color brandNavy = Color(0xFF011A4D);

  // Surfaces
  static const Color background = Color(0xFFF5F9FC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color loginBackground = Color(0xFFF0F4FF);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textGray600 = Color(0xFF6B7280);
  static const Color textGray700 = Color(0xFF374151);
  static const Color textGray800 = Color(0xFF1F2937);
  static const Color textGray900 = Color(0xFF111827);

  // Auth / login
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color splashTitle = Color(0xFF0EA5E9);
  static const Color signInButton = Color(0xFF111827);
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color placeholder = Color(0xFFD1D5DB);

  // Accents
  static const Color star = Color(0xFFF59E0B);
  static const Color starBright = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color starRating = Color(0xFFFBBF24);
  static const Color specCircleFill = Color(0xFF57D2E8);
  static const Color logoTeal = Color(0xFF57D2E8);
  static const Color roleAvatarBg = Color(0xFFDBEAFE);

  // Legacy aliases used across app
  static const Color primary = medcluesTeal;
  static const Color primaryLight = medcluesTealLight;
  static const Color secondary = brandCyan;
  static const Color secondaryLight = Color(0xFFE0F7FA);
  static const Color surface = white;
  static const Color card = white;
  static const Color divider = Color(0xFFF3F4F6);

  // Hero gradient
  static const List<Color> heroGradient = [
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
    Color(0xFF38BDF8),
  ];

  // Login blobs
  static const Color blobLeft = Color(0xFFC7D9F5);
  static const Color blobRight = Color(0xFFD6E8FF);

  // Doctor card left borders
  static const List<Color> doctorBorderColors = [
    Color(0xFF0EA5E9),
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
  ];
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.brandNavy.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get loginCard => [
        BoxShadow(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
