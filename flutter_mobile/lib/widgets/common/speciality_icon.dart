import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/speciality_assets.dart';

/// Renders web-matched speciality icon (PNG or SVG).
class SpecialityIcon extends StatelessWidget {
  const SpecialityIcon({
    super.key,
    required this.specialityName,
    this.size = 36,
    this.color,
  });

  final String specialityName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final path = SpecialityAssets.assetPathFor(specialityName);
    if (path == null) {
      return Icon(Icons.medical_services, size: size, color: color ?? Colors.white);
    }
    if (SpecialityAssets.isSvg(path)) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      );
    }
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }
}
