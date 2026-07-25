import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'medclues_palette.dart';

/// Vector reconstruction of the MEDCLUES shield-M logo with staged micro-elements.
/// All drawing uses Canvas transforms — no layout passes during animation loops.
class MedcluesLogoPainter extends CustomPainter {
  MedcluesLogoPainter({
    required this.masterT,
    this.microT = 1,
    this.textT = 1,
    this.microOpacity = 1,
    this.showShieldOnly = false,
    this.showCrossOnly = false,
  });

  /// Global timeline 0→1 across 2.5s splash.
  final double masterT;
  final double microT;
  final double textT;
  final double microOpacity;
  final bool showShieldOnly;
  final bool showCrossOnly;

  static double shieldScale(double t) =>
      MedcluesPalette.emphasized.transform((t / 0.32).clamp(0.0, 1.0));

  static double stageMicro(double t) => ((t - 0.32) / 0.28).clamp(0.0, 1.0);

  static double stageText(double t) => ((t - 0.60) / 0.40).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = shieldScale(masterT);
    if (scale <= 0.001) return;

    final center = Offset(size.width * 0.5, size.height * 0.46);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    if (!showCrossOnly) {
      _drawShieldM(canvas, size);
    }
    if (!showShieldOnly) {
      _drawMedicalCross(canvas, size);
      if (microOpacity > 0) {
        _drawLeftEmergency(canvas, size, microT * microOpacity);
        _drawRightCalendar(canvas, size, microT * microOpacity);
      }
    }

    canvas.restore();
  }

  void _drawShieldM(Canvas canvas, Size size) {
    final w = size.width * 0.72;
    final h = size.height * 0.62;

    final shield = _shieldPath(w, h);
    final leftClip = Path()
      ..addRect(Rect.fromLTWH(-w, -h, w, h * 2));
    final rightClip = Path()
      ..addRect(Rect.fromLTWH(0, -h, w, h * 2));

    final navyFade = Curves.easeIn.transform((masterT / 0.32).clamp(0.0, 1.0));
    final tealFade = Curves.easeOut.transform(((masterT - 0.08) / 0.28).clamp(0.0, 1.0));

    canvas.save();
    canvas.clipPath(shield);
    canvas.save();
    canvas.clipPath(leftClip);
    final navyPaint = Paint()..color = MedcluesPalette.deepNavy.withValues(alpha: navyFade);
    canvas.drawPath(_mLeftPath(w, h), navyPaint);
    canvas.restore();

    canvas.save();
    canvas.clipPath(rightClip);
    final tealPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.1, -h * 0.3),
        Offset(w * 0.55, h * 0.4),
        [MedcluesPalette.medicalTeal, MedcluesPalette.medicalCyan],
      )
      ..color = MedcluesPalette.medicalTeal.withValues(alpha: tealFade);
    canvas.drawPath(_mRightPath(w, h), tealPaint);
    canvas.restore();
    canvas.restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = MedcluesPalette.deepNavy.withValues(alpha: 0.08 * navyFade);
    canvas.drawPath(shield, stroke);
  }

  Path _shieldPath(double w, double h) {
    return Path()
      ..moveTo(0, -h * 0.42)
      ..quadraticBezierTo(-w * 0.52, -h * 0.38, -w * 0.48, h * 0.05)
      ..quadraticBezierTo(-w * 0.42, h * 0.48, 0, h * 0.52)
      ..quadraticBezierTo(w * 0.42, h * 0.48, w * 0.48, h * 0.05)
      ..quadraticBezierTo(w * 0.52, -h * 0.38, 0, -h * 0.42)
      ..close();
  }

  Path _mLeftPath(double w, double h) {
    return Path()
      ..moveTo(-w * 0.34, h * 0.38)
      ..lineTo(-w * 0.34, -h * 0.12)
      ..lineTo(-w * 0.08, h * 0.18)
      ..lineTo(-w * 0.08, -h * 0.28)
      ..lineTo(-w * 0.02, -h * 0.28)
      ..lineTo(-w * 0.02, h * 0.38)
      ..close();
  }

  Path _mRightPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.02, h * 0.38)
      ..lineTo(w * 0.02, -h * 0.28)
      ..lineTo(w * 0.08, -h * 0.28)
      ..lineTo(w * 0.08, h * 0.18)
      ..lineTo(w * 0.34, -h * 0.12)
      ..lineTo(w * 0.34, h * 0.38)
      ..close();
  }

  void _drawMedicalCross(Canvas canvas, Size size) {
    final crossT = Curves.easeOutCubic.transform(microT.clamp(0.0, 1.0));
    final slideY = (1 - crossT) * 18;
    canvas.save();
    canvas.translate(0, -size.height * 0.34 + slideY);

    final crossPaint = Paint()..color = MedcluesPalette.medicalTeal.withValues(alpha: crossT);
    final barW = size.width * 0.09;
    final barH = size.width * 0.22;
    final r = Radius.circular(barW * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: barW, height: barH), r),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: barH, height: barW), r),
      crossPaint,
    );

    final ecgT = Curves.easeInOut.transform(((microT - 0.15) / 0.85).clamp(0.0, 1.0));
    if (ecgT > 0) {
      final ecg = _ecgPath(size.width * 0.18);
      final metrics = ecg.computeMetrics().first;
      final drawLen = metrics.length * ecgT;
      final extracted = metrics.extractPath(0, drawLen);
      final glow = Paint()
        ..color = MedcluesPalette.pureWhite.withValues(alpha: 0.35 * ecgT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(extracted, glow);
      final ecgPaint = Paint()
        ..color = MedcluesPalette.pureWhite.withValues(alpha: ecgT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(extracted, ecgPaint);
    }
    canvas.restore();
  }

  Path _ecgPath(double w) {
    return Path()
      ..moveTo(-w * 0.5, 0)
      ..lineTo(-w * 0.28, 0)
      ..lineTo(-w * 0.18, -w * 0.22)
      ..lineTo(-w * 0.06, w * 0.28)
      ..lineTo(w * 0.04, -w * 0.38)
      ..lineTo(w * 0.14, w * 0.18)
      ..lineTo(w * 0.28, 0)
      ..lineTo(w * 0.5, 0);
  }

  void _drawLeftEmergency(Canvas canvas, Size size, double t) {
    final eased = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
    final slideX = (1 - eased) * -28;
    canvas.save();
    canvas.translate(-size.width * 0.38 + slideX, -size.height * 0.02);

    final streakPaint = Paint()
      ..color = MedcluesPalette.pureWhite.withValues(alpha: 0.85 * t)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = i * 5.0 - 7;
      canvas.drawLine(Offset(-16 - i * 3.0, y), Offset(-4 - i * 1.5, y), streakPaint);
    }

    final siren = Paint()..color = MedcluesPalette.pureWhite.withValues(alpha: t);
    canvas.drawCircle(const Offset(6, 0), 5, siren);
    final ray = Paint()
      ..color = MedcluesPalette.medicalCyan.withValues(alpha: 0.7 * t)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.45;
      canvas.drawLine(
        Offset(6 + math.cos(angle) * 6, math.sin(angle) * 6),
        Offset(6 + math.cos(angle) * 11, math.sin(angle) * 11),
        ray,
      );
    }
    canvas.restore();
  }

  void _drawRightCalendar(Canvas canvas, Size size, double t) {
    final bounce = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    canvas.save();
    canvas.translate(size.width * 0.34, size.height * 0.04);
    canvas.scale(0.6 + bounce * 0.4);

    final calW = size.width * 0.16;
    final calH = size.width * 0.17;
    final calR = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: calW, height: calH),
      const Radius.circular(4),
    );
    canvas.drawRRect(calR, Paint()..color = MedcluesPalette.pureWhite.withValues(alpha: t));
    canvas.drawRRect(
      RRect.fromLTRBR(-calW / 2, -calH / 2, calW / 2, -calH / 2 + calH * 0.28, const Radius.circular(3)),
      Paint()..color = MedcluesPalette.medicalTeal.withValues(alpha: t),
    );

    final checkT = Curves.easeInOut.transform(((t - 0.35) / 0.65).clamp(0.0, 1.0));
    if (checkT > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(-calW / 2, -calH / 2, calW * checkT, calH));
      final check = Paint()
        ..color = MedcluesPalette.medicalTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final p = Path()
        ..moveTo(-calW * 0.12, 0)
        ..lineTo(-calW * 0.02, calH * 0.12)
        ..lineTo(calW * 0.14, -calH * 0.08);
      canvas.drawPath(p, check);
      canvas.drawCircle(
        Offset(calW * 0.22, calH * 0.22),
        calW * 0.11,
        Paint()..color = MedcluesPalette.medicalTeal.withValues(alpha: checkT),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MedcluesLogoPainter old) =>
      old.masterT != masterT ||
      old.microT != microT ||
      old.textT != textT ||
      old.microOpacity != microOpacity ||
      old.showShieldOnly != showShieldOnly ||
      old.showCrossOnly != showCrossOnly;
}
