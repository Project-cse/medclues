import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../themes/premium_theme_colors.dart';

/// Corporate healthcare booking — clean borders, navy accents, restrained elevation.
abstract final class PremiumBookingTheme {
  static const Color primaryBlue = Color(0xFF003B8E);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color starGold = Color(0xFFF59E0B);

  static Color background(BuildContext context) =>
      PremiumThemeColors.of(context).background;
  static Color white(BuildContext context) =>
      PremiumThemeColors.of(context).surface;
  static Color text(BuildContext context) => PremiumThemeColors.of(context).text;
  static Color textSecondary(BuildContext context) =>
      PremiumThemeColors.of(context).textSecondary;
  static Color border(BuildContext context) =>
      PremiumThemeColors.of(context).border;
  static Color chipSelectedBg(BuildContext context) =>
      PremiumThemeColors.of(context).chipSelectedBg;
  static Color securityBg(BuildContext context) =>
      PremiumThemeColors.of(context).securityBg;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static const double horizontalPadding = 20;
  static const double cardRadius = 16;
  static const double chipRadius = 10;
  static const double dateCardRadius = 12;
  static const double buttonRadius = 12;
  static const double buttonHeight = 56;
  static const double sectionGap = 24;

  static List<BoxShadow> cardShadow(BuildContext context) {
    if (_isDark(context)) return const [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> softShadow(BuildContext context) {
    if (_isDark(context)) return const [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF003B8E), Color(0xFF002654)],
  );

  static const LinearGradient selectedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF003B8E), Color(0xFF0047AB)],
  );

  static List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Standard corporate card — bordered surface, restrained elevation.
  static BoxDecoration corporateCard(BuildContext context) {
    final dark = _isDark(context);
    return BoxDecoration(
      color: white(context),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: dark ? border(context) : border(context).withValues(alpha: 0.9),
      ),
      boxShadow: cardShadow(context),
    );
  }

  /// Icon badge used in section card headers.
  static BoxDecoration iconBadge(BuildContext context) {
    return BoxDecoration(
      color: chipSelectedBg(context),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: accentBlue.withValues(alpha: _isDark(context) ? 0.25 : 0.12),
      ),
    );
  }

  static TextStyle sectionTitleStyle(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: text(context),
        letterSpacing: -0.15,
        height: 1.25,
      );

  static TextStyle sectionSubtitleStyle(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary(context),
        height: 1.4,
      );

  static TextStyle corporateLabelStyle(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary(context),
        letterSpacing: 0.6,
        height: 1.2,
      );
}
