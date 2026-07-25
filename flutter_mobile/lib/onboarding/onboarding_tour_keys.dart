import 'package:flutter/material.dart';

/// Registers soft-tour targets and resolves holes in overlay-local coordinates.
abstract final class OnboardingTourKeys {
  static final search = GlobalKey(debugLabel: 'tour-search');
  static final doctors = GlobalKey(debugLabel: 'tour-doctors');
  static final emergency = GlobalKey(debugLabel: 'tour-emergency');

  /// Map a target [GlobalKey] into the coordinate space of [overlayContext]
  /// (the spotlight layer). Avoids wrong holes when screen vs overlay origins differ.
  static Rect? rectInOverlay(GlobalKey key, BuildContext overlayContext) {
    final targetCtx = key.currentContext;
    if (targetCtx == null) return null;
    final targetBox = targetCtx.findRenderObject();
    final overlayBox = overlayContext.findRenderObject();
    if (targetBox is! RenderBox || overlayBox is! RenderBox) return null;
    if (!targetBox.hasSize || !targetBox.attached) return null;
    if (!overlayBox.hasSize || !overlayBox.attached) return null;

    final targetTopLeft = targetBox.localToGlobal(Offset.zero);
    final overlayTopLeft = overlayBox.localToGlobal(Offset.zero);
    final local = targetTopLeft - overlayTopLeft;
    final rect = local & targetBox.size;
    if (rect.width < 8 || rect.height < 8) return null;
    // Ignore absurd off-screen measurements (common while animate() is running).
    if (rect.top < -80 || rect.left < -40) return null;
    return rect.inflate(2);
  }
}
