import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../brand/medclues_palette.dart';
import '../../config/app_config.dart';

enum MedcluesLogoSize { auth, large, compact }

/// MEDCLUES logo — transparent, no wrapper background.
class MedcluesLogoImage extends StatelessWidget {
  const MedcluesLogoImage({
    super.key,
    this.size = MedcluesLogoSize.auth,
    this.useHero = false,
    this.heroTag = MedcluesPalette.heroLogoTag,
  });

  static const assetPath = 'assets/images/medclues_logo.png';

  final MedcluesLogoSize size;
  final bool useHero;
  final String heroTag;

  double _logoWidth(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return switch (size) {
      MedcluesLogoSize.large => math.min(screenW * 0.72, 280.0),
      MedcluesLogoSize.auth => math.min(screenW * 0.64, 240.0),
      MedcluesLogoSize.compact => math.min(screenW * 0.48, 180.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = _logoWidth(context);

    Widget logo = Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (_, __, ___) => Text(
        AppConfig.appName,
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: MedcluesPalette.deepNavy,
        ),
      ),
    );

    if (useHero) {
      logo = Hero(
        tag: heroTag,
        child: Material(type: MaterialType.transparency, child: logo),
      );
    }

    return logo;
  }
}
