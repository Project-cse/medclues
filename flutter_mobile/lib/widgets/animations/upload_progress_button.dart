import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

enum UploadButtonState { idle, uploading, success }

class UploadProgressButton extends StatelessWidget {
  const UploadProgressButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.idleLabel = 'Choose files & upload',
  });

  final UploadButtonState state;
  final VoidCallback onPressed;
  final String idleLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state == UploadButtonState.uploading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: state == UploadButtonState.success
              ? AppColors.logoTeal
              : const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
          child: _buildChild(),
        ),
      ),
    );
  }

  Widget _buildChild() {
    switch (state) {
      case UploadButtonState.uploading:
        return Row(
          key: const ValueKey('uploading'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Uploading…',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        );
      case UploadButtonState.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 22)
                .animate()
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms),
            const SizedBox(width: 10),
            Text(
              'Uploaded successfully',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        );
      case UploadButtonState.idle:
        return Row(
          key: const ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              idleLabel,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        );
    }
  }
}
