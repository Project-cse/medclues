import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/theme_context.dart';

/// Theme-aware list row skeleton (labs, blood banks, appointments).
class ListCardSkeleton extends StatelessWidget {
  const ListCardSkeleton({
    super.key,
    this.height = 108,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final double height;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Shimmer(
        period: const Duration(milliseconds: 1200),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [
            context.skeletonHighlight,
            context.skeletonShimmer,
            context.skeletonHighlight,
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.skeletonBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.skeletonLine,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.skeletonLine,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: context.skeletonLine,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 10,
                      width: 180,
                      decoration: BoxDecoration(
                        color: context.skeletonLine,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
