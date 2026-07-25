import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'medclues_palette.dart';

/// Stage 3 branding — MEDCLUES wordmark + subtext with kerning expansion.
class MedcluesBrandTypography extends StatelessWidget {
  const MedcluesBrandTypography({
    super.key,
    required this.textT,
    this.compact = false,
  });

  final double textT;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fade = Curves.easeOut.transform(textT.clamp(0.0, 1.0));
    final slideY = (1 - fade) * (compact ? 8 : 16);
    final letterSpacing = 4.0 - (3.0 * fade);

    return Opacity(
      opacity: fade,
      child: Transform.translate(
        offset: Offset(0, slideY),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: compact ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: letterSpacing,
                ),
                children: const [
                  TextSpan(text: 'MED', style: TextStyle(color: MedcluesPalette.deepNavy)),
                  TextSpan(text: 'CLUES', style: TextStyle(color: MedcluesPalette.medicalTeal)),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 6),
              Text(
                '— EMERGENCY | BOOKING —',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: MedcluesPalette.deepNavy.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dotLine(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'SINCE 2026',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: MedcluesPalette.softSlate,
                      ),
                    ),
                  ),
                  _dotLine(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dotLine() {
    return Row(
      children: [
        Container(width: 28, height: 1, color: MedcluesPalette.slate200),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: MedcluesPalette.medicalTeal,
            shape: BoxShape.circle,
          ),
        ),
        Container(width: 28, height: 1, color: MedcluesPalette.slate200),
      ],
    );
  }
}
