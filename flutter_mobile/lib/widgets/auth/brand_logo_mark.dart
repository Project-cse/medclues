import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../brand/medclues_palette.dart';
import '../animations/app_motion.dart';
import '../animations/healthcare_motion.dart';
import '../brand/medclues_logo_image.dart';

/// Login / registration header — large transparent logo, no duplicate name.
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.logoSize = MedcluesLogoSize.auth,
    this.useHero = true,
  });

  final MedcluesLogoSize logoSize;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MedcluesLogoImage(
        size: logoSize,
        useHero: useHero,
      ).logoSlideDown(),
    );
  }
}

/// Welcome copy only — brand name lives inside the logo image.
class BrandHeaderText extends StatelessWidget {
  const BrandHeaderText({
    super.key,
    this.headline = 'Welcome Back!',
    this.subheadline = 'Sign in to continue to your account',
    this.animationIndex = 1,
  });

  final String headline;
  final String subheadline;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 32,
          height: 2,
          decoration: BoxDecoration(
            color: MedcluesPalette.medicalTeal,
            borderRadius: BorderRadius.circular(1),
          ),
        )
            .authEnter(index: animationIndex)
            .animate()
            .scaleX(begin: 0, end: 1, duration: 600.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 14),
        Text(
          headline,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MedcluesPalette.deepNavy,
          ),
        ).titleReveal(),
        const SizedBox(height: 4),
        Text(
          subheadline,
          style: GoogleFonts.poppins(fontSize: 14, color: MedcluesPalette.softSlate),
        ).authEnter(index: animationIndex + 1),
      ],
    );
  }
}
