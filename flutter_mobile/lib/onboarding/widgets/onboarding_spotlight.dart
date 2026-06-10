import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/l10n_extension.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../onboarding_tour_steps.dart';

enum _ArrowSide { top, bottom, left, right }

class _TooltipLayout {
  const _TooltipLayout({
    required this.offset,
    required this.maxWidth,
    required this.arrowSide,
    required this.arrowOffset,
  });

  final Offset offset;
  final double maxWidth;
  final _ArrowSide arrowSide;
  final double arrowOffset;
}

/// Professional coach-mark: spotlight hole + smart tooltip (top / bottom / left / right).
class OnboardingSpotlight extends StatefulWidget {
  const OnboardingSpotlight({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    this.canGoBack = true,
    this.isLastTourStep = false,
  });

  final OnboardingTourStep step;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final bool canGoBack;
  final bool isLastTourStep;

  @override
  State<OnboardingSpotlight> createState() => _OnboardingSpotlightState();
}

class _OnboardingSpotlightState extends State<OnboardingSpotlight>
    with TickerProviderStateMixin {
  static const _tooltipPad = 14.0;
  static const _arrow = 12.0;
  static const _gap = 10.0;
  static const _estTooltipH = 210.0;

  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Rect? _fromHole;
  Rect? _toHole;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
    );
    _enter.forward();
  }

  @override
  void didUpdateWidget(OnboardingSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.index != widget.step.index) {
      _fromHole = oldWidget.step.target.rectFor(MediaQuery.sizeOf(context));
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Rect _anchorFor(Size size) => widget.step.target.rectFor(size);

  TooltipPlacement _resolvePlacement(Size size, EdgeInsets pad, Rect hole, TooltipPlacement pref) {
    if (pref != TooltipPlacement.auto) return pref;
    final spaceBelow = size.height - hole.bottom - pad.bottom;
    final spaceAbove = hole.top - pad.top;
    final spaceRight = size.width - hole.right - pad.right;
    final spaceLeft = hole.left - pad.left;
    if (spaceBelow >= _estTooltipH + 40) return TooltipPlacement.below;
    if (spaceAbove >= _estTooltipH + 40) return TooltipPlacement.above;
    if (spaceRight >= 260) return TooltipPlacement.right;
    if (spaceLeft >= 260) return TooltipPlacement.left;
    return spaceBelow >= spaceAbove ? TooltipPlacement.below : TooltipPlacement.above;
  }

  _TooltipLayout _layoutTooltip(Size size, EdgeInsets pad, Rect hole) {
    final maxW = math.min(size.width - 28, 360.0);
    final cx = hole.center.dx;
    final pick = _resolvePlacement(size, pad, hole, widget.step.target.placement);

    if (pick == TooltipPlacement.right) {
      final top = (hole.center.dy - _estTooltipH / 2).clamp(pad.top, size.height - _estTooltipH - pad.bottom);
      return _TooltipLayout(
        offset: Offset(hole.right + _gap + _arrow, top),
        maxWidth: maxW,
        arrowSide: _ArrowSide.left,
        arrowOffset: (hole.center.dy - top).clamp(40.0, _estTooltipH - 40.0),
      );
    }

    if (pick == TooltipPlacement.left) {
      final top = (hole.center.dy - _estTooltipH / 2).clamp(pad.top, size.height - _estTooltipH - pad.bottom);
      return _TooltipLayout(
        offset: Offset(hole.left - maxW - _gap - _arrow, top),
        maxWidth: maxW,
        arrowSide: _ArrowSide.right,
        arrowOffset: (hole.center.dy - top).clamp(40.0, _estTooltipH - 40.0),
      );
    }

    final left = (cx - maxW / 2).clamp(_tooltipPad, size.width - maxW - _tooltipPad);
    final arrowOff = (cx - left).clamp(28.0, maxW - 28.0);

    if (pick == TooltipPlacement.above) {
      var top = hole.top - _estTooltipH - _gap - _arrow;
      if (top < pad.top) top = hole.bottom + _gap + _arrow;
      final above = top < hole.top;
      return _TooltipLayout(
        offset: Offset(left, top),
        maxWidth: maxW,
        arrowSide: above ? _ArrowSide.bottom : _ArrowSide.top,
        arrowOffset: arrowOff,
      );
    }

    // below (default)
    var top = hole.bottom + _gap + _arrow;
    if (top + _estTooltipH > size.height - pad.bottom) {
      top = hole.top - _estTooltipH - _gap - _arrow;
    }
    final below = top > hole.bottom;
    return _TooltipLayout(
      offset: Offset(left, top),
      maxWidth: maxW,
      arrowSide: below ? _ArrowSide.top : _ArrowSide.bottom,
      arrowOffset: arrowOff,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final anchor = _anchorFor(size);
    final radius = widget.step.target.borderRadius;
    final layout = _layoutTooltip(size, pad, anchor);

    return LayoutBuilder(
      builder: (context, _) {
        return Stack(
          children: [
            // Light scrim + small anchor ring (no cut-out blocks)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_enter, _pulse]),
                    builder: (context, _) {
                      final t = _enter.value;
                      final animatedAnchor = _fromHole != null
                          ? Rect.lerp(_fromHole, anchor, t) ?? anchor
                          : anchor;
                      final pulse = 1 + _pulse.value * 0.02;
                      return CustomPaint(
                        painter: _SpotlightPainter(
                          anchor: animatedAnchor,
                          anchorRadius: radius,
                          pulseScale: pulse,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Floating tooltip (only interactive layer — scrim does not block page taps)
            Positioned(
              left: layout.offset.dx,
              top: layout.offset.dy,
              width: layout.maxWidth,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: _CoachBubble(
                    step: widget.step,
                    totalSteps: widget.totalSteps,
                    canGoBack: widget.canGoBack,
                    isLastTourStep: widget.isLastTourStep,
                    arrowSide: layout.arrowSide,
                    arrowOffset: layout.arrowOffset,
                    onNext: widget.onNext,
                    onPrevious: widget.onPrevious,
                    onSkip: widget.onSkip,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.anchor,
    required this.anchorRadius,
    required this.pulseScale,
  });

  final Rect anchor;
  final double anchorRadius;
  final double pulseScale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B1220).withValues(alpha: 0.28),
    );

    final ring = RRect.fromRectAndRadius(anchor, Radius.circular(anchorRadius));
    canvas.drawRRect(
      ring,
      Paint()
        ..color = PremiumHealthcareTheme.secondaryBlue.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawRRect(
      ring.inflate(4 * pulseScale),
      Paint()
        ..color = PremiumHealthcareTheme.secondaryBlue.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.anchor != anchor || old.pulseScale != pulseScale;
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({
    required this.step,
    required this.totalSteps,
    required this.canGoBack,
    required this.isLastTourStep,
    required this.arrowSide,
    required this.arrowOffset,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  final OnboardingTourStep step;
  final int totalSteps;
  final bool canGoBack;
  final bool isLastTourStep;
  final _ArrowSide arrowSide;
  final double arrowOffset;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = step.index / totalSteps;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: arrowSide == _ArrowSide.top ? -10 : null,
            bottom: arrowSide == _ArrowSide.bottom ? -10 : null,
            left: arrowSide == _ArrowSide.left
                ? -10
                : (arrowSide == _ArrowSide.top || arrowSide == _ArrowSide.bottom)
                    ? arrowOffset - 10
                    : null,
            right: arrowSide == _ArrowSide.right ? -10 : null,
            child: _Arrow(side: arrowSide),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: PremiumHealthcareTheme.border(context).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumHealthcareTheme.primaryBlue.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: PremiumHealthcareTheme.border(context).withValues(alpha: 0.35),
                        valueColor: const AlwaysStoppedAnimation(PremiumHealthcareTheme.secondaryBlue),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: PremiumHealthcareTheme.heroGradient,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(step.icon, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.title(l10n),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: PremiumHealthcareTheme.text(context),
                                      ),
                                    ),
                                    Text(
                                      '${step.index}/$totalSteps',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: PremiumHealthcareTheme.secondaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            step.message(l10n),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.5,
                              color: PremiumHealthcareTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(
                              totalSteps,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: i + 1 == step.index ? 18 : 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: i + 1 == step.index
                                      ? PremiumHealthcareTheme.secondaryBlue
                                      : PremiumHealthcareTheme.border(context),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: onSkip,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.onboardingSkip,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: PremiumHealthcareTheme.textSecondary(context),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (canGoBack) ...[
                                OutlinedButton(
                                  onPressed: onPrevious,
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: PremiumHealthcareTheme.primaryBlue,
                                    side: BorderSide(color: PremiumHealthcareTheme.primaryBlue.withValues(alpha: 0.28)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(l10n.commonBack, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                                const SizedBox(width: 6),
                              ],
                              ElevatedButton(
                                onPressed: onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PremiumHealthcareTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  isLastTourStep ? l10n.commonContinue : l10n.onboardingNext,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.side});

  final _ArrowSide side;

  @override
  Widget build(BuildContext context) {
    const c = Colors.white;
    final path = Path();
    switch (side) {
      case _ArrowSide.top:
        path.moveTo(0, 10);
        path.lineTo(10, 0);
        path.lineTo(20, 10);
      case _ArrowSide.bottom:
        path.moveTo(0, 0);
        path.lineTo(10, 10);
        path.lineTo(20, 0);
      case _ArrowSide.left:
        path.moveTo(10, 0);
        path.lineTo(0, 10);
        path.lineTo(10, 20);
      case _ArrowSide.right:
        path.moveTo(0, 0);
        path.lineTo(10, 10);
        path.lineTo(0, 20);
    }
    path.close();
    return CustomPaint(
      size: const Size(20, 20),
      painter: _TrianglePainter(path, c),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.path, this.color);
  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => false;
}
