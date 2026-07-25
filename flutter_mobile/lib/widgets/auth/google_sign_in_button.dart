import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_login_theme.dart';

/// Google Identity–style sign-in — matches premium login card.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Continue with Google',
    this.loadingLabel = 'Signing in…',
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: PremiumLoginTheme.fieldHeight,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: PremiumLoginTheme.white,
          foregroundColor: PremiumLoginTheme.text,
          side: const BorderSide(color: PremiumLoginTheme.inputBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PremiumLoginTheme.fieldRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PremiumLoginTheme.textSecondary,
                ),
              )
            else
              const _GoogleGLogo(size: 18),
            const SizedBox(width: 12),
            Text(
              loading ? loadingLabel : label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: loading ? PremiumLoginTheme.textSecondary : PremiumLoginTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 3.14, 1.57, true, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), -1.57, 1.57, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 1.57, 1.57, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 0, 1.57, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.52, h * 0.52), w * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
