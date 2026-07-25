import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'medclues_brand_typography.dart';
import 'medclues_logo_painter.dart';
import 'medclues_palette.dart';

enum MedcluesLogoMode { splashAnimated, headerStatic, heroFlight }

/// Unified MEDCLUES logo anchor — drives splash timeline or static header via Hero.
class MedcluesLogoWidget extends StatefulWidget {
  const MedcluesLogoWidget({
    super.key,
    this.size = 200,
    this.mode = MedcluesLogoMode.splashAnimated,
    this.externalT,
    this.microOpacity = 1,
    this.showBranding = true,
    this.useHero = false,
  });

  final double size;
  final MedcluesLogoMode mode;
  final double? externalT;
  final double microOpacity;
  final bool showBranding;
  final bool useHero;

  @override
  State<MedcluesLogoWidget> createState() => _MedcluesLogoWidgetState();
}

class _MedcluesLogoWidgetState extends State<MedcluesLogoWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.mode == MedcluesLogoMode.splashAnimated && widget.externalT == null) {
      _controller = AnimationController(
        vsync: this,
        duration: MedcluesPalette.splashTotal,
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  double get _t {
    if (widget.externalT != null) return widget.externalT!.clamp(0.0, 1.0);
    if (_controller != null) return _controller!.value;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isHeader = widget.mode == MedcluesLogoMode.headerStatic ||
        widget.mode == MedcluesLogoMode.heroFlight;
    final masterT = isHeader ? 1.0 : _t;
    final microT = isHeader ? 0.0 : MedcluesLogoPainter.stageMicro(_t);
    final textT = isHeader ? 0.0 : MedcluesLogoPainter.stageText(_t);
    final microOpacity = isHeader ? 0.0 : widget.microOpacity;

    Widget logo = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller ?? AlwaysStoppedAnimation(_t),
        builder: (_, __) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size * 0.82,
                child: CustomPaint(
                  painter: MedcluesLogoPainter(
                    masterT: masterT,
                    microT: microT,
                    textT: textT,
                    microOpacity: microOpacity,
                    showShieldOnly: isHeader,
                  ),
                ),
              ),
              if (widget.showBranding && !isHeader && textT > 0) ...[
                const SizedBox(height: 12),
                MedcluesBrandTypography(
                  textT: textT,
                  compact: widget.size < 140,
                ),
              ],
            ],
          );
        },
      ),
    );

    if (widget.useHero) {
      logo = Hero(
        tag: MedcluesPalette.heroLogoTag,
        flightShuttleBuilder: (ctx, anim, dir, from, to) {
          final t = Curves.easeInOutCubic.transform(anim.value);
          final size = lerpDouble(widget.size, 72, t) ?? widget.size;
          return MedcluesLogoWidget(
            size: size,
            mode: MedcluesLogoMode.heroFlight,
            showBranding: false,
            microOpacity: 1 - t,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: logo,
        ),
      );
    }

    return logo;
  }
}
