import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/blood_bank_model.dart';

/// Teardrop blood-type icon — same shape as web `BloodBankCard.jsx` / design reference.
class BloodDropIcon extends StatelessWidget {
  const BloodDropIcon({
    super.key,
    required this.label,
    required this.status,
    this.size = 48,
  });

  final String label;
  final BloodStockStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    final dropW = size * 0.85;
    final dropH = size;

    return SizedBox(
      width: dropW,
      height: dropH + 4,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: Size(dropW, dropH),
            painter: _BloodDropPainter(
              fill: style.fill,
              stroke: style.stroke,
              glowColor: style.glow,
            ),
          ),
          if (label.isNotEmpty)
            Positioned(
              top: dropH * 0.42,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: label.length > 2 ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: style.label,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static ({Color fill, Color stroke, Color label, Color? glow}) _styleFor(BloodStockStatus status) {
    return switch (status) {
      BloodStockStatus.available => (
          fill: const Color(0xFFEF4444),
          stroke: const Color(0xFFDC2626),
          label: Colors.white,
          glow: const Color(0xFFDC2626),
        ),
      BloodStockStatus.limited => (
          fill: const Color(0xFFF59E0B),
          stroke: const Color(0xFFD97706),
          label: const Color(0xFF78350F),
          glow: const Color(0xFFF59E0B),
        ),
      BloodStockStatus.unavailable => (
          fill: const Color(0xFFF1F5F9),
          stroke: const Color(0xFFE2E8F0),
          label: const Color(0xFF94A3B8),
          glow: null,
        ),
    };
  }
}

class _BloodDropPainter extends CustomPainter {
  _BloodDropPainter({
    required this.fill,
    required this.stroke,
    this.glowColor,
  });

  final Color fill;
  final Color stroke;
  final Color? glowColor;

  /// Path from Agora/web BloodBankCard SVG (viewBox 0 0 24 24).
  static Path _teardropPath(Size size) {
    const viewBox = 24.0;
    final path = Path();
    final sx = size.width / viewBox;
    final sy = size.height / viewBox;
    double x(double v) => v * sx;
    double y(double v) => v * sy;

    path.moveTo(x(12), y(22));
    path.cubicTo(x(16.4183), y(22), x(20), y(18.4183), x(20), y(14));
    path.cubicTo(x(20), y(8), x(12), y(2), x(12), y(2));
    path.cubicTo(x(12), y(2), x(4), y(8), x(4), y(14));
    path.cubicTo(x(4), y(18.4183), x(7.58172), y(22), x(12), y(22));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _teardropPath(size);

    if (glowColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = glowColor!.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BloodDropPainter old) =>
      old.fill != fill || old.stroke != stroke || old.glowColor != glowColor;
}
