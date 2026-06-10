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
    background: Color(0xFF0B0F14),
    surface: Color(0xFF141A22),
    text: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF243044),
    chipSelectedBg: Color(0xFF152A45),
    securityBg: Color(0xFF0F1A2E),
  );

  static PremiumThemeColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
