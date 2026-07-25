import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../brand/medclues_palette.dart';

/// Opening intro video — scales to fill the full screen (BoxFit.cover).
class FullscreenSplashVideo extends StatelessWidget {
  const FullscreenSplashVideo({
    super.key,
    required this.controller,
    this.fallbackWidth = 1080,
    this.fallbackHeight = 1920,
  });

  final VideoPlayerController controller;
  final double fallbackWidth;
  final double fallbackHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        final w = controller.value.size.width > 0
            ? controller.value.size.width
            : fallbackWidth;
        final h = controller.value.size.height > 0
            ? controller.value.size.height
            : fallbackHeight;

        return ColoredBox(
          color: MedcluesPalette.splashCanvas,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              if (maxW <= 0 || maxH <= 0) {
                return const SizedBox.shrink();
              }

              // Cover: fill entire screen; center crop if aspect ratios differ.
              final scale = math.max(maxW / w, maxH / h);
              final fittedW = w * scale;
              final fittedH = h * scale;

              return ClipRect(
                child: Center(
                  child: SizedBox(
                    width: fittedW,
                    height: fittedH,
                    child: VideoPlayer(controller),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
