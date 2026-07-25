import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animations/morph_action_button.dart' show MorphButtonState;
import 'premium_login_theme.dart';
import 'sign_in_pulse_loader.dart';

/// Full-width navy gradient CTA — pulse ECG loader, success checkmark.
class PremiumSignInButton extends StatelessWidget {
  const PremiumSignInButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
  });

  final String label;
  final MorphButtonState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final loading = state == MorphButtonState.loading;
    final success = state == MorphButtonState.success;
    final busy = state != MorphButtonState.idle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: PremiumLoginTheme.buttonHeight,
      decoration: BoxDecoration(
        gradient: success
            ? const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
              )
            : PremiumLoginTheme.signInGradient,
        borderRadius: BorderRadius.circular(PremiumLoginTheme.buttonRadius),
        border: loading
            ? Border.all(
                color: PremiumLoginTheme.accentBlue.withValues(alpha: 0.35),
                width: 1,
              )
            : null,
        boxShadow: loading
            ? PremiumLoginTheme.buttonLoadingGlow
            : (busy ? null : PremiumLoginTheme.buttonShadow),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(PremiumLoginTheme.buttonRadius),
          child: Center(child: _inner()),
        ),
      ),
    );
  }

  Widget _inner() {
    switch (state) {
      case MorphButtonState.loading:
        return const SignInPulseLoader();
      case MorphButtonState.success:
        return const Icon(
          Icons.check_rounded,
          color: PremiumLoginTheme.white,
          size: 28,
        );
      case MorphButtonState.idle:
        return Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: PremiumLoginTheme.white,
            letterSpacing: 0.2,
          ),
        );
    }
  }
}
