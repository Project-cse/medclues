import 'package:flutter/material.dart';

/// Shared light/dark palette for premium hospital + booking flows.
class PremiumThemeColors {
  const PremiumThemeColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.chipSelectedBg,
    required this.securityBg,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color chipSelectedBg;
  final Color securityBg;

  static const light = PremiumThemeColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    chipSelectedBg: Color(0xFFEFF6FF),
    securityBg: Color(0xFFF0F7FF),
  );

  static const dark = PremiumThemeColors(
    background: Color(0xFF000000),
    surface: Color(0xFF1A1A1A),
    text: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFB0B0B0),
    border: Color(0xFF2E2E2E),
    chipSelectedBg: Color(0xFF2A2A2A),
    securityBg: Color(0xFF1A1A1A),
  );

  static PremiumThemeColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
