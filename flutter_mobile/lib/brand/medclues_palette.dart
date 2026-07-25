import 'package:flutter/material.dart';

/// MEDCLUES clinical brand palette — extracted from official logo geometry.
abstract final class MedcluesPalette {
  static const Color deepNavy = Color(0xFF002855);
  static const Color medicalTeal = Color(0xFF009F93);
  static const Color medicalCyan = Color(0xFF00B4D8);
  static const Color pureWhite = Color(0xFFFFFFFF);
  /// Splash letterbox — matches video background (#f5f5f5) for seamless full-screen feel.
  static const Color splashCanvas = Color(0xFFF5F5F5);
  static const Color softSlate = Color(0xFF64748B);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);

  /// Material 3 Emphasized decelerate — Cubic(0.2, 0.0, 0, 1.0).
  static const Curve emphasized = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve elasticDamp = Curves.elasticOut;

  static const Duration splashTotal = Duration(milliseconds: 2500);
  static const Duration stage1 = Duration(milliseconds: 800);
  static const Duration stage2 = Duration(milliseconds: 700);
  static const Duration stage3 = Duration(milliseconds: 1000);

  static const int dashboardStaggerMs = 60;
  static const double loginFieldSlideDp = 40;

  static const String heroLogoTag = 'medclues_logo_anchor';
}
