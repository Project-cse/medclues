import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';

/// Right-side illustration for the homepage hero banner.
/// 35% column · centered · responsive · no crop · transparent asset only.
class HeroBannerIllustration extends StatelessWidget {
  const HeroBannerIllustration({super.key});

  static double _illustrationSize(double screenWidth, double areaWidth) {
    final double base;
    if (screenWidth <= 360) {
      base = 95;
    } else if (screenWidth <= 390) {
      base = 115;
    } else if (screenWidth <= 430) {
      base = 125;
    } else {
      base = 135;
    }

    final bannerWidth = areaWidth / 0.35;
    final maxByBanner = bannerWidth * 0.40;
    final maxByArea = areaWidth * 0.88;
    final maxAllowed = maxByBanner < maxByArea ? maxByBanner : maxByArea;
    return base.clamp(90.0, 140.0).clamp(0.0, maxAllowed);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth;
        final areaHeight = constraints.maxHeight;
        final illustrationSize = _illustrationSize(screenWidth, areaWidth);
        final circleSize = illustrationSize * 1.14;

        return Padding(
          padding: const EdgeInsets.only(right: 18),
          child: SizedBox(
            width: areaWidth,
            height: areaHeight,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  SizedBox(
                    width: illustrationSize,
                    height: illustrationSize,
                    child: Image.asset(
                      AppAssets.bannerNavigation,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      isAntiAlias: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
