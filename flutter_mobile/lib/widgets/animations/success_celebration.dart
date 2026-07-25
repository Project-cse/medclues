import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

/// GPay / PhonePe style success — circle expand + checkmark + text.
class SuccessCelebration extends StatelessWidget {
  const SuccessCelebration({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(duration: 400.ms),
              Animate(
                effects: [
                  FadeEffect(delay: 200.ms, duration: 400.ms),
                  ScaleEffect(
                    delay: 200.ms,
                    duration: 450.ms,
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),
                ],
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 100,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ).animate(delay: 350.ms).fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ).animate(delay: 450.ms).fadeIn(duration: 400.ms),
        ],
        if (child != null) ...[
          const SizedBox(height: 24),
          child!.animate(delay: 550.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
        ],
      ],
    );
  }
}
