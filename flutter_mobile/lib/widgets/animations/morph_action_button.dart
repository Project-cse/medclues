import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import 'healthcare_motion.dart';

enum MorphButtonState { idle, loading, success }

/// Login / register CTA — morphs to spinner then checkmark.
class MorphActionButton extends StatelessWidget {
  const MorphActionButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
    this.color,
  });

  final String label;
  final MorphButtonState state;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.signInButton;
    final isBusy = state != MorphButtonState.idle;

    return AnimatedContainer(
      duration: HealthcareMotion.standard,
      curve: HealthcareMotion.easeInOut,
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isBusy && state == MorphButtonState.loading ? 27 : 12),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onPressed,
          borderRadius: BorderRadius.circular(isBusy ? 27 : 12),
          child: Center(
            child: AnimatedSwitcher(
              duration: HealthcareMotion.standard,
              switchInCurve: HealthcareMotion.easeOut,
              child: _content(state),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, duration: 450.ms);
  }

  Widget _content(MorphButtonState s) {
    switch (s) {
      case MorphButtonState.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        );
      case MorphButtonState.success:
        return const Icon(
          key: ValueKey('success'),
          Icons.check_rounded,
          color: Colors.white,
          size: 30,
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOutBack);
      case MorphButtonState.idle:
        return Text(
          key: const ValueKey('label'),
          label,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        );
    }
  }
}
