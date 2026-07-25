import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../brand/medclues_palette.dart';

/// Fits splash video to portrait mobile viewport. Rebuilds as metadata arrives (web-safe).
class MobileFitVideo extends StatelessWidget {
  const MobileFitVideo({
    super.key,
    required this.controller,
    this.backgroundColor = MedcluesPalette.pureWhite,
    this.maxPhoneWidth = 430,
    this.fallbackAspectRatio = 9 / 16,
  });

  final VideoPlayerController controller;
  final Color backgroundColor;
  final double maxPhoneWidth;
  final double fallbackAspectRatio;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        final screen = MediaQuery.sizeOf(context);
        final rawAr = controller.value.aspectRatio;
        final aspectRatio = rawAr > 0.01 ? rawAr : fallbackAspectRatio;

        final frameWidth = screen.width > maxPhoneWidth ? maxPhoneWidth : screen.width;
        final frameHeight = screen.height;

        var displayW = frameWidth;
        var displayH = displayW / aspectRatio;

        if (displayH > frameHeight) {
          displayH = frameHeight;
          displayW = displayH * aspectRatio;
        }

        return ColoredBox(
          color: backgroundColor,
          child: Center(
            child: SizedBox(
              width: displayW,
              height: displayH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screen.width > maxPhoneWidth ? 12 : 0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: controller.value.size.width > 0
                        ? controller.value.size.width
                        : displayW,
                    height: controller.value.size.height > 0
                        ? controller.value.size.height
                        : displayH,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
