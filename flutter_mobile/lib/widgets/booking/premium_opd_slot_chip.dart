import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_booking_theme.dart';

/// Full-width OPD / video slot selector — corporate outlined style with capacity badge.
class PremiumOpdSlotChip extends StatelessWidget {
  const PremiumOpdSlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.remainingCount,
    this.remainingLabel,
    this.fullLabel,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final int? remainingCount;
  final String? remainingLabel;
  final String? fullLabel;

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? PremiumBookingTheme.textSecondary(context).withValues(alpha: 0.6)
        : selected
            ? Colors.white
            : PremiumBookingTheme.text(context);

    final showCapacity = remainingCount != null;
    final isFull = showCapacity && remainingCount! <= 0;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: selected && enabled ? PremiumBookingTheme.selectedGradient : null,
          color: !enabled
              ? PremiumBookingTheme.background(context)
              : selected
                  ? null
                  : PremiumBookingTheme.white(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected && enabled
                ? PremiumBookingTheme.primaryBlue
                : PremiumBookingTheme.border(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected && enabled
                        ? Colors.white.withValues(alpha: 0.9)
                        : PremiumBookingTheme.accentBlue.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: selected && enabled
                      ? Colors.white.withValues(alpha: 0.9)
                      : PremiumBookingTheme.accentBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      height: 1.25,
                    ),
                  ),
                ),
                if (selected && enabled)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: PremiumBookingTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  ),
              ],
            ),
            if (showCapacity) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected && enabled
                      ? Colors.white.withValues(alpha: 0.12)
                      : isFull
                          ? PremiumBookingTheme.background(context)
                          : PremiumBookingTheme.chipSelectedBg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected && enabled
                        ? Colors.white.withValues(alpha: 0.2)
                        : PremiumBookingTheme.border(context),
                  ),
                ),
                child: Text(
                  isFull ? (fullLabel ?? 'Full') : (remainingLabel ?? '$remainingCount'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFull
                        ? PremiumBookingTheme.textSecondary(context)
                        : selected && enabled
                            ? Colors.white
                            : PremiumBookingTheme.accentBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
