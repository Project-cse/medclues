import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_healthcare_theme.dart';

class PremiumBookingHeroHeader extends StatelessWidget {
  const PremiumBookingHeroHeader({
    super.key,
    required this.doctorName,
    required this.onClose,
  });

  final String doctorName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        MediaQuery.paddingOf(context).top + 16,
        PremiumHealthcareTheme.horizontalPadding,
        48,
      ),
      decoration: const BoxDecoration(gradient: PremiumHealthcareTheme.heroGradient),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Appointment',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'with $doctorName',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumFlowBackButton extends StatelessWidget {
  const PremiumFlowBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_rounded, size: 20, color: PremiumHealthcareTheme.text(context)),
            const SizedBox(width: 6),
            Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: PremiumHealthcareTheme.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumSectionTitleRow extends StatelessWidget {
  const PremiumSectionTitleRow({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: PremiumHealthcareTheme.secondaryBlue),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PremiumHealthcareTheme.text(context),
          ),
        ),
      ],
    );
  }
}

class PremiumWhoOptionCard extends StatelessWidget {
  const PremiumWhoOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PremiumHealthcareTheme.white(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PremiumHealthcareTheme.border(context)),
          boxShadow: PremiumHealthcareTheme.fieldShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PremiumHealthcareTheme.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: PremiumHealthcareTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: PremiumHealthcareTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}
