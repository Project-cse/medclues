import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../animations/app_motion.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Sign In',
    this.animationIndex = 8,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signInButton,
          disabledBackgroundColor: AppColors.signInButton.withValues(alpha: 0.65),
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    )
        .buttonPop(index: animationIndex)
        .animate(target: loading ? 1 : 0)
        .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.25));
  }
}
