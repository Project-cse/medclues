import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Anime.js-style motion presets for MedClues (Flutter-native; works on Android/iOS).
extension AppMotion on Widget {
  /// Opening splash — elastic scale + fade (hero reveal).
  Widget splashHero({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: 700.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.35, 0.35),
          end: const Offset(1, 1),
          duration: 1100.ms,
          curve: Curves.elasticOut,
        )
        .blur(begin: const Offset(8, 0), end: Offset.zero, duration: 600.ms);
  }

  /// Staggered auth screen entrance (login / register fields & cards).
  Widget authEnter({int index = 0, bool fromRight = false}) {
    final delayMs = 70 * index;
    return animate(delay: delayMs.ms)
        .fadeIn(duration: 520.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.14, end: 0, duration: 560.ms, curve: Curves.easeOutCubic)
        .slideX(
          begin: fromRight ? 0.06 : 0,
          end: 0,
          duration: 560.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
          duration: 560.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Register screen — slide in from right (distinct from login).
  Widget registerEnter({int index = 0}) => authEnter(index: index, fromRight: true);

  /// Continuous floating blob (background).
  Widget floatBlob({Duration? duration, double amplitude = 10}) {
    return animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -amplitude, end: amplitude, duration: (duration ?? 3200.ms), curve: Curves.easeInOut)
        .scaleXY(begin: 0.96, end: 1.04, duration: 4000.ms, curve: Curves.easeInOut);
  }

  /// Logo pulse + soft shimmer.
  Widget brandPulse() {
    return animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.05, duration: 2000.ms, curve: Curves.easeInOut)
        .shimmer(duration: 2800.ms, color: Colors.white.withValues(alpha: 0.35));
  }

  /// Primary CTA button entrance.
  Widget buttonPop({int index = 0}) {
    return animate(delay: (90 * index).ms)
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 480.ms,
          curve: Curves.elasticOut,
        );
  }

  /// Success / transition shimmer sweep.
  Widget shimmerPass() {
    return animate()
        .shimmer(duration: 1200.ms, delay: 200.ms, color: Colors.white.withValues(alpha: 0.4))
        .then()
        .shake(hz: 2, duration: 400.ms);
  }

  /// Typing-style title reveal.
  Widget titleReveal({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.25, end: 0, duration: 550.ms, curve: Curves.easeOutCubic)
        .blur(begin: const Offset(4, 0), end: Offset.zero, duration: 400.ms);
  }
}

/// Gradient backdrop for splash / auth (animated opacity).
class MotionGradientBackdrop extends StatelessWidget {
  const MotionGradientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F4FC),
                Color(0xFFF5F9FC),
                Color(0xFFE0F2FE),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.15)),
        child,
      ],
    );
  }
}
