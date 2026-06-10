import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_booking_theme.dart';

class PremiumSymptomChip extends StatelessWidget {
  const PremiumSymptomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? PremiumBookingTheme.selectedGradient : null,
          color: selected ? null : PremiumBookingTheme.white(context),
          borderRadius: BorderRadius.circular(PremiumBookingTheme.chipRadius),
          border: Border.all(
            color: selected
                ? PremiumBookingTheme.primaryBlue
                : PremiumBookingTheme.border(context),
          ),
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : PremiumBookingTheme.text(context),
            height: 1.15,
          ),
        ),
      ),
    );
  }
}
