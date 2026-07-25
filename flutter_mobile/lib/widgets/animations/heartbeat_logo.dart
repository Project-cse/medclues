import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Medical cross logo with heartbeat pulse rings — splash hero.
class HeartbeatLogo extends StatefulWidget {
  const HeartbeatLogo({
    super.key,
    this.size = 120,
    this.onComplete,
  });

  final double size;
  final VoidCallback? onComplete;

  @override
  State<HeartbeatLogo> createState() => _HeartbeatLogoState();
}

class _HeartbeatLogoState extends State<HeartbeatLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.55, curve: Curves.easeOutCubic)),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1, curve: Curves.easeOut)),
    );
    _controller.forward().then((_) => widget.onComplete?.call());
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final s = _scale.value;
        final p = _pulse.value;
        return SizedBox(
          width: widget.size * 1.6,
          height: widget.size * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft glow
              Container(
                width: widget.size * 1.35 * p,
                height: widget.size * 1.35 * p,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: _glow.value),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.logoTeal.withValues(alpha: _glow.value * 0.6),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Heartbeat ring
              CustomPaint(
                size: Size(widget.size * 1.2 * p, widget.size * 1.2 * p),
                painter: _PulseRingPainter(
                  progress: _controller.value,
                  color: AppColors.primaryBlue.withValues(alpha: 0.18),
                ),
              ),
              // Logo mark
              Transform.scale(
                scale: s,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF0EA5E9)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: widget.size * 0.42,
                        color: Colors.white,
                      ),
                      Positioned(
                        right: widget.size * 0.18,
                        bottom: widget.size * 0.18,
                        child: Icon(Icons.favorite, size: widget.size * 0.14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final wave = 1 + math.sin(progress * math.pi * 2) * 0.04;
    canvas.drawCircle(center, radius * wave, paint);
    canvas.drawCircle(center, radius * 0.82 * wave, paint..color = color.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter old) => old.progress != progress;
}
