import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_login_theme.dart';

/// Healthcare pulse loader — ECG line + expanding rings, no spinner.
class SignInPulseLoader extends StatefulWidget {
  const SignInPulseLoader({
    super.key,
    this.label = 'Signing In...',
  });

  final String label;

  @override
  State<SignInPulseLoader> createState() => _SignInPulseLoaderState();
}

class _SignInPulseLoaderState extends State<SignInPulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: const Size(220, 56),
              painter: _SignInPulseRingsPainter(t: t),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 22,
                  child: CustomPaint(
                    painter: _EcgLinePainter(
                      progress: t,
                      color: PremiumLoginTheme.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PremiumLoginTheme.white,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Soft concentric waves emanating from button center.
class _SignInPulseRingsPainter extends CustomPainter {
  _SignInPulseRingsPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const ringCount = 3;

    for (var i = 0; i < ringCount; i++) {
      final phase = (t + i / ringCount) % 1.0;
      final radius = 18 + phase * 52;
      final alpha = (1 - phase) * 0.28;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 - (phase * 0.8)
        ..color = PremiumLoginTheme.accentBlue.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, paint);
    }

    final glow = Paint()
      ..shader = ui.Gradient.radial(
        center,
        28,
        [
          PremiumLoginTheme.accentBlue.withValues(alpha: 0.14),
          PremiumLoginTheme.accentBlue.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(center, 28, glow);
  }

  @override
  bool shouldRepaint(covariant _SignInPulseRingsPainter old) => old.t != t;
}

/// Animated ECG heartbeat trace.
class _EcgLinePainter extends CustomPainter {
  _EcgLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  Path _path(Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    return Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.18, mid)
      ..lineTo(w * 0.28, mid - h * 0.42)
      ..lineTo(w * 0.38, mid + h * 0.55)
      ..lineTo(w * 0.48, mid - h * 0.72)
      ..lineTo(w * 0.58, mid + h * 0.35)
      ..lineTo(w * 0.72, mid)
      ..lineTo(w, mid);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final metrics = path.computeMetrics().first;
    final drawLen = metrics.length * (0.55 + 0.45 * Curves.easeInOut.transform(progress));

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final extracted = metrics.extractPath(0, drawLen);
    canvas.drawPath(extracted, glowPaint);
    canvas.drawPath(extracted, linePaint);
  }

  @override
  bool shouldRepaint(covariant _EcgLinePainter old) =>
      old.progress != progress || old.color != color;
}
