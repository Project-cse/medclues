import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../brand/medclues_palette.dart';

/// MEDCLUES motion design tokens — clinical-grade, 60/120 FPS targets.
abstract final class HealthcareMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration splash = MedcluesPalette.splashTotal;

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutQuart;
  static const Curve emphasized = MedcluesPalette.emphasized;

  static const int staggerMs = MedcluesPalette.dashboardStaggerMs;
}

extension HealthcareMotionExt on Widget {
  /// Dashboard / list cards — slide up + fade, 100ms stagger.
  Widget dashboardStagger(int index) {
    final d = (HealthcareMotion.staggerMs * index).ms;
    return animate(delay: d)
        .fadeIn(duration: HealthcareMotion.slow, curve: HealthcareMotion.easeOut)
        .slideY(begin: 0.08, end: 0, duration: HealthcareMotion.slow, curve: HealthcareMotion.easeOut);
  }

  /// Auth form slide from bottom (+40dp → 0, staggered matrix).
  Widget authFormEnter({int index = 0}) {
    final d = (70 * index).ms;
    final slide = MedcluesPalette.loginFieldSlideDp / 400;
    return animate(delay: d)
        .fadeIn(duration: 520.ms, curve: HealthcareMotion.easeOut)
        .slideY(begin: slide, end: 0, duration: 560.ms, curve: HealthcareMotion.emphasized);
  }

  /// Logo slides from top on login.
  Widget logoSlideDown({int index = 0}) {
    return animate(delay: (60 * index).ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: -0.12, end: 0, duration: 500.ms, curve: HealthcareMotion.easeOut);
  }

  /// Wizard horizontal page feel.
  Widget wizardPageEnter({bool fromRight = true}) {
    return animate()
        .fadeIn(duration: 400.ms)
        .slideX(
          begin: fromRight ? 0.06 : -0.06,
          end: 0,
          duration: HealthcareMotion.standard,
          curve: HealthcareMotion.easeOut,
        );
  }

  /// Search result card entrance.
  Widget searchResultEnter(int index) {
    return animate(delay: (50 * index).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 420.ms);
  }

  /// Receipt line-by-line reveal.
  Widget receiptLine(int index) {
    return animate(delay: (80 * index).ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.03, end: 0, duration: 380.ms);
  }

}
