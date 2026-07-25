import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/speciality_assets.dart';
import '../../constants/home_specialities.dart';
import '../../utils/theme_context.dart';
import 'premium_speciality_theme.dart';

/// Specialty cell — circular icon + label only (no outer card).
class PremiumSpecialityCard extends StatelessWidget {
  const PremiumSpecialityCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    this.iconSize = PremiumSpecialityTheme.iconSize,
  });

  final HomeSpeciality item;
  final bool selected;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: PremiumSpecialityTheme.primaryBlue.withValues(alpha: 0.08),
        highlightColor: PremiumSpecialityTheme.primaryBlue.withValues(alpha: 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconRing(
              path: item.assetPath,
              size: iconSize,
              isDark: isDark,
              selected: selected,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: PremiumSpecialityTheme.labelHeight,
              child: Center(
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: isDark ? context.primaryText : PremiumSpecialityTheme.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({
    required this.path,
    required this.size,
    required this.isDark,
    required this.selected,
  });

  final String path;
  final double size;
  final bool isDark;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PremiumSpecialityTheme.selectionDuration,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? (isDark ? const Color(0xFF0C4A6E) : PremiumSpecialityTheme.selectedBg)
            : (isDark ? const Color(0xFF1E3A5F) : PremiumSpecialityTheme.iconBg),
        border: Border.all(
          color: PremiumSpecialityTheme.primaryBlue,
          width: selected ? 2 : 1.5,
        ),
        boxShadow: selected ? PremiumSpecialityTheme.selectedGlow : null,
      ),
      padding: EdgeInsets.all(size * 0.14),
      child: _asset(path),
    );
  }

  Widget _asset(String path) {
    if (path.isEmpty) {
      return const Icon(Icons.medical_services_outlined, size: 24);
    }
    if (SpecialityAssets.isSvg(path)) {
      return SvgPicture.asset(path, fit: BoxFit.contain);
    }
    return Image.asset(path, fit: BoxFit.contain);
  }
}
