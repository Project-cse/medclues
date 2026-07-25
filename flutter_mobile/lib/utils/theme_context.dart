import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Theme-aware semantic colors — use instead of hardcoded [AppColors] in widgets.
extension MedcluesThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => theme.colorScheme;
  bool get isDark => theme.brightness == Brightness.dark;

  Color get cardColor => cs.surface;
  Color get scaffoldBg => theme.scaffoldBackgroundColor;
  Color get primaryText => cs.onSurface;
  Color get secondaryText => cs.onSurfaceVariant;
  Color get hintText => isDark ? const Color(0xFF64748B) : AppColors.textHint;
  Color get borderColor => cs.outline;
  Color get highlightBg =>
      isDark ? const Color(0xFF1E3A5F) : AppColors.brandBlueLight;
  Color get chipSelectedBg =>
      isDark ? const Color(0xFF1E3A5F) : AppColors.brandBlueLight;
  Color get chipUnselectedBg => isDark ? const Color(0xFF1A1A1A) : AppColors.white;
  Color get iconMuted => secondaryText;
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.brandNavy.withValues(alpha: 0.08);

  /// Shimmer / skeleton placeholders — subtle on true-black dark mode.
  Color get skeletonBase => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8EDF2);
  Color get skeletonHighlight => isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9);
  Color get skeletonLine => isDark ? const Color(0xFF333333) : const Color(0xFFCBD5E1);
  Color get skeletonShimmer => isDark ? const Color(0xFF3A3A3A) : Colors.white;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  BoxDecoration cardDecoration({double radius = 16, BorderSide? side}) =>
      BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: side != null ? Border.fromBorderSide(side) : Border.all(color: borderColor),
        boxShadow: cardShadow,
      );
}
