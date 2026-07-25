import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../brand/medclues_palette.dart';
import 'morph_action_button.dart' show MorphButtonState;

/// Advanced MEDCLUES CTA — width collapse → spinner → teal checkmark → expand mask.
class MorphingButton extends StatefulWidget {
  const MorphingButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
    this.baseColor,
    this.onSuccessExpand,
  });

  final String label;
  final MorphButtonState state;
  final VoidCallback? onPressed;
  final Color? baseColor;
  final VoidCallback? onSuccessExpand;

  @override
  State<MorphingButton> createState() => _MorphingButtonState();
}

class _MorphingButtonState extends State<MorphingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant MorphingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != MorphButtonState.success && widget.state == MorphButtonState.success) {
      _expandCtrl.forward(from: 0).then((_) => widget.onSuccessExpand?.call());
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  Color get _bg {
    if (widget.state == MorphButtonState.success) return MedcluesPalette.medicalTeal;
    return widget.baseColor ?? MedcluesPalette.deepNavy;
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.state != MorphButtonState.idle;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: MedcluesPalette.emphasized,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: MedcluesPalette.emphasized,
                width: busy ? 56 : constraints.maxWidth,
                height: 54,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(busy ? 28 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: _bg.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: busy ? null : widget.onPressed,
                    borderRadius: BorderRadius.circular(busy ? 28 : 12),
                    child: Center(child: _inner()),
                  ),
                ),
              ),
            ),
            if (widget.state == MorphButtonState.success)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _expandCtrl,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _CircleMaskPainter(progress: _expandCtrl.value),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _inner() {
    switch (widget.state) {
      case MorphButtonState.loading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: MedcluesPalette.pureWhite,
          ),
        );
      case MorphButtonState.success:
        return const Icon(
          Icons.check_rounded,
          color: MedcluesPalette.pureWhite,
          size: 28,
        );
      case MorphButtonState.idle:
        return AnimatedOpacity(
          opacity: widget.state == MorphButtonState.idle ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MedcluesPalette.pureWhite,
              letterSpacing: 0.4,
            ),
          ),
        );
    }
  }
}

class _CircleMaskPainter extends CustomPainter {
  _CircleMaskPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 6;
    final paint = Paint()
      ..color = MedcluesPalette.medicalTeal.withValues(alpha: 0.18 * (1 - progress))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR * progress, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleMaskPainter old) => old.progress != progress;
}
