import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../animations/app_motion.dart';
import 'premium_login_theme.dart';

/// Soft abstract blue shapes — top of premium login canvas.
class LoginBlobs extends StatelessWidget {
  const LoginBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -80,
          left: -100,
          child: _OrganicBlob(
            width: 320,
            height: 260,
            color: PremiumLoginTheme.blobSoft.withValues(alpha: 0.75),
            radii: const BorderRadius.only(
              bottomRight: Radius.circular(180),
              topRight: Radius.circular(120),
              bottomLeft: Radius.circular(90),
            ),
          ).floatBlob(duration: 4200.ms, amplitude: 8),
        ),
        Positioned(
          top: -20,
          right: -70,
          child: _OrganicBlob(
            width: 240,
            height: 200,
            color: PremiumLoginTheme.blobAccent.withValues(alpha: 0.65),
            radii: const BorderRadius.only(
              bottomLeft: Radius.circular(140),
              topLeft: Radius.circular(100),
              bottomRight: Radius.circular(60),
            ),
          )
              .floatBlob(duration: 3600.ms, amplitude: 10)
              .animate(delay: 150.ms)
              .fadeIn(duration: 800.ms),
        ),
        Positioned(
          top: 100,
          right: 24,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PremiumLoginTheme.accentBlue.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ).floatBlob(duration: 5000.ms, amplitude: 5),
        ),
      ],
    );
  }
}

class _OrganicBlob extends StatelessWidget {
  const _OrganicBlob({
    required this.width,
    required this.height,
    required this.color,
    required this.radii,
  });

  final double width;
  final double height;
  final Color color;
  final BorderRadius radii;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radii,
      ),
    );
  }
}
