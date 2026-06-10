import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_booking_theme.dart';

class PremiumDateChip extends StatelessWidget {
  const PremiumDateChip({
    super.key,
    required this.weekdayLabel,
    required this.dayNum,
    required this.monthShort,
    required this.selected,
    required this.onTap,
  });

  final String weekdayLabel;
  final int dayNum;
  final String monthShort;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: selected ? PremiumBookingTheme.selectedGradient : null,
          color: selected ? null : PremiumBookingTheme.white(context),
          borderRadius: BorderRadius.circular(PremiumBookingTheme.dateCardRadius),
          border: selected
              ? null
              : Border.all(color: PremiumBookingTheme.border(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : PremiumBookingTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayNum',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1,
                color: selected ? Colors.white : PremiumBookingTheme.text(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthShort,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white.withValues(alpha: 0.8)
                    : PremiumBookingTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumDateNavButton extends StatelessWidget {
  const PremiumDateNavButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: PremiumBookingTheme.white(context),
          shape: BoxShape.circle,
          border: Border.all(color: PremiumBookingTheme.border(context)),
        ),
        child: const Icon(
          Icons.chevron_right_rounded,
          color: PremiumBookingTheme.primaryBlue,
          size: 24,
        ),
      ),
    );
  }
}
