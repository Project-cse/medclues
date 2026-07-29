import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/route_names.dart';

/// Pulsing red SOS / star-of-life style emergency control for the home header.
class BlinkingEmergencyIconButton extends StatefulWidget {
  const BlinkingEmergencyIconButton({
    super.key,
    this.tooltip = 'Emergency Help',
  });

  final String tooltip;

  @override
  State<BlinkingEmergencyIconButton> createState() =>
      _BlinkingEmergencyIconButtonState();
}

class _BlinkingEmergencyIconButtonState
    extends State<BlinkingEmergencyIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable) {
      _controller.stop();
      _controller.value = 1.0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: () => context.push(RouteNames.emergency),
      icon: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935)
                      .withValues(alpha: 0.25 + 0.45 * t),
                  blurRadius: 4 + 8 * t,
                  spreadRadius: 0.5 * t,
                ),
              ],
            ),
            child: Opacity(
              opacity: t,
              child: const CustomPaint(
                size: Size(22, 22),
                painter: _SosStarPainter(color: Color(0xFFE53935)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Six-pointed medical asterisk / star-of-life glyph (matches SOS mark).
class _SosStarPainter extends CustomPainter {
  const _SosStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.shortestSide * 0.48;
    final inner = outer * 0.38;

    final path = Path();
    for (var i = 0; i < 6; i++) {
      final aOuter = -math.pi / 2 + i * math.pi / 3;
      final aInner = aOuter + math.pi / 6;
      final ox = cx + outer * math.cos(aOuter);
      final oy = cy + outer * math.sin(aOuter);
      final ix = cx + inner * math.cos(aInner);
      final iy = cy + inner * math.sin(aInner);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);

    canvas.drawCircle(Offset(cx, cy), outer * 0.18, paint);
  }

  @override
  bool shouldRepaint(covariant _SosStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
