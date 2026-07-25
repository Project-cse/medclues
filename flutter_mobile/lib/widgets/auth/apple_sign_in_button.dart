import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_login_theme.dart';

/// Apple Sign-In button — matches the premium login card style.
/// Uses a black Apple logo (official Apple HIG branding).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Continue with Apple',
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
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.black),
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
                  color: Colors.white54,
                ),
              )
            else
              const _AppleLogo(size: 20),
            const SizedBox(width: 10),
            Text(
              loading ? loadingLabel : label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: loading ? Colors.white54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the Apple  logo using CustomPainter — no asset needed.
class _AppleLogo extends StatelessWidget {
  const _AppleLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppleLogoPainter()),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Scale factor
    final s = w / 14.0;

    final path = Path();

    // Apple logo path (simplified shape matching Apple's official logo proportions)
    // Main apple body
    path.moveTo(7 * s, 2.5 * s);
    path.cubicTo(7.8 * s, 1.3 * s, 9.2 * s, 0.5 * s, 10.5 * s, 0.5 * s);
    path.cubicTo(10.7 * s, 1.9 * s, 10.1 * s, 3.3 * s, 9.3 * s, 4.2 * s);
    path.cubicTo(8.5 * s, 5.1 * s, 7.2 * s, 5.8 * s, 5.9 * s, 5.7 * s);
    path.cubicTo(5.7 * s, 4.3 * s, 6.2 * s, 3.0 * s, 7 * s, 2.5 * s);
    path.close();

    // Apple body left
    path.moveTo(5.5 * s, 6.5 * s);
    path.cubicTo(4.0 * s, 6.5 * s, 2.0 * s, 7.5 * s, 1.2 * s, 9.5 * s);
    path.cubicTo(0.0 * s, 12.0 * s, 0.8 * s, 15.5 * s, 2.5 * s, 17.5 * s);
    path.cubicTo(3.5 * s, 18.8 * s, 4.5 * s, 19.5 * s, 5.5 * s, 19.5 * s);
    path.cubicTo(6.5 * s, 19.5 * s, 7.0 * s, 19.0 * s, 8.0 * s, 19.0 * s);
    path.cubicTo(9.0 * s, 19.0 * s, 9.5 * s, 19.5 * s, 10.5 * s, 19.5 * s);
    path.cubicTo(11.5 * s, 19.5 * s, 12.5 * s, 18.8 * s, 13.5 * s, 17.5 * s);
    path.cubicTo(14.5 * s, 16.0 * s, 15.0 * s, 14.5 * s, 15.0 * s, 13.0 * s);
    path.cubicTo(15.0 * s, 13.0 * s, 12.5 * s, 12.0 * s, 12.5 * s, 9.5 * s);
    path.cubicTo(12.5 * s, 7.5 * s, 13.8 * s, 6.5 * s, 14.0 * s, 6.5 * s);
    path.cubicTo(13.0 * s, 5.2 * s, 11.5 * s, 4.5 * s, 9.5 * s, 5.5 * s);
    path.cubicTo(8.5 * s, 6.0 * s, 7.5 * s, 6.5 * s, 7.0 * s, 6.5 * s);
    path.cubicTo(6.5 * s, 6.5 * s, 6.0 * s, 6.5 * s, 5.5 * s, 6.5 * s);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
