import 'package:flutter/material.dart';

import '../../brand/medclues_palette.dart';

/// Canvas-driven radiating signal pulses — 60 FPS, no layout rebuilds.
class SignalPulsePainter extends CustomPainter {
  SignalPulsePainter({required this.t, this.ringCount = 4});

  final double t;
  final int ringCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.48;

    for (var i = 0; i < ringCount; i++) {
      final phase = (t + i / ringCount) % 1.0;
      final radius = maxR * (0.35 + phase * 0.65);
      final alpha = (1 - phase) * 0.42;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 - phase
        ..color = MedcluesPalette.medicalTeal.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, paint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          MedcluesPalette.medicalTeal.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.35));
    canvas.drawCircle(center, maxR * 0.35, glow);
  }

  @override
  bool shouldRepaint(covariant SignalPulsePainter old) => old.t != t;
}

class SignalPulseRing extends StatefulWidget {
  const SignalPulseRing({super.key, required this.size});

  final double size;

  @override
  State<SignalPulseRing> createState() => _SignalPulseRingState();
}

class _SignalPulseRingState extends State<SignalPulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: SignalPulsePainter(t: _ctrl.value),
        ),
      ),
    );
  }
}

/// Portrait mask with layered signal rings for video pre-connect HUD.
class MedcluesConnectingHud extends StatelessWidget {
  const MedcluesConnectingHud({super.key, this.doctorName, this.portraitUrl});

  final String? doctorName;
  final String? portraitUrl;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MedcluesPalette.deepNavy,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SignalPulseRing(size: 200),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: MedcluesPalette.medicalTeal.withValues(alpha: 0.5), width: 2),
                      image: portraitUrl != null
                          ? DecorationImage(image: NetworkImage(portraitUrl!), fit: BoxFit.cover)
                          : null,
                      color: MedcluesPalette.deepNavy.withValues(alpha: 0.6),
                    ),
                    child: portraitUrl == null
                        ? const Icon(Icons.person, size: 48, color: Colors.white70)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting to Doctor...',
              style: TextStyle(
                color: MedcluesPalette.pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (doctorName != null) ...[
              const SizedBox(height: 6),
              Text(doctorName!, style: TextStyle(color: Colors.white60, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
