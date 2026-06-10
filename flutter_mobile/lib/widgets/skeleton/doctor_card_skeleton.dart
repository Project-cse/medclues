import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../brand/medclues_palette.dart';
import '../../utils/theme_context.dart';

/// Medical wireframe skeleton — 45° diagonal shimmer sweep @ 1200ms.
class DoctorCardSkeleton extends StatelessWidget {
  const DoctorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = context.skeletonBase;
    final highlight = context.skeletonHighlight;
    final shimmerMid = context.skeletonShimmer;
    final line = context.skeletonLine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer(
        period: const Duration(milliseconds: 1200),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [highlight, shimmerMid, highlight],
          stops: const [0.1, 0.5, 0.9],
        ),
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                ColoredBox(
                  color: MedcluesPalette.medicalTeal.withValues(alpha: context.isDark ? 0.5 : 0.35),
                  child: const SizedBox(width: 4, height: 100),
                ),
                Expanded(
                  child: Container(
                    color: base,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: line,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 12, width: 140, color: line),
                              const SizedBox(height: 8),
                              Container(height: 10, width: 90, color: line),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
