import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/tutorial_step.dart';

/// Premium coach-mark / step tutorial overlay.
class AppTutorialOverlay extends StatefulWidget {
  const AppTutorialOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
    this.accentColor = const Color(0xFF2563EB),
  });

  final List<TutorialStep> steps;
  final VoidCallback onFinished;
  final Color accentColor;

  static Future<void> show(
    BuildContext context, {
    required List<TutorialStep> steps,
    required VoidCallback onFinished,
    Color accentColor = const Color(0xFF2563EB),
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => AppTutorialOverlay(
        steps: steps,
        onFinished: () {
          Navigator.of(ctx).pop();
          onFinished();
        },
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<AppTutorialOverlay> createState() => _AppTutorialOverlayState();
}

class _AppTutorialOverlayState extends State<AppTutorialOverlay> {
  int _index = 0;

  TutorialStep get _step => widget.steps[_index];
  bool get _isLast => _index >= widget.steps.length - 1;

  Rect? _targetRect() {
    final key = _step.targetKey;
    if (key == null) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height);
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    setState(() => _index++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _skip() => widget.onFinished();

  @override
  Widget build(BuildContext context) {
    final target = _targetRect();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TutorialScrimPainter(
                hole: target?.inflate(8),
                borderColor: widget.accentColor,
              ),
            ),
          ),
          if (target != null && _step.highlightLabel != null)
            Positioned(
              left: target.left,
              top: target.top - 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _step.highlightLabel!,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomInset + 24,
            child: _TutorialCard(
              step: _step,
              index: _index,
              total: widget.steps.length,
              accentColor: widget.accentColor,
              isLast: _isLast,
              onSkip: _skip,
              onNext: _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.step,
    required this.index,
    required this.total,
    required this.accentColor,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  final TutorialStep step;
  final int index;
  final int total;
  final Color accentColor;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(step.icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Step ${index + 1} of $total',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                step.body,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  total,
                  (i) => Container(
                    width: i == index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i == index ? accentColor : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Skip tour',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isLast ? 'Got it' : 'Next',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialScrimPainter extends CustomPainter {
  _TutorialScrimPainter({this.hole, required this.borderColor});

  final Rect? hole;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.72);
    final full = Offset.zero & size;

    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }

    final path = Path()
      ..addRect(full)
      ..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(16)), border);
  }

  @override
  bool shouldRepaint(covariant _TutorialScrimPainter old) =>
      old.hole != hole || old.borderColor != borderColor;
}
