import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/image_url_helper.dart';

/// Matches mobile/components/ui/AvatarImage.tsx
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.uri,
    this.size = 56,
    this.borderColor = AppColors.specCircleFill,
  });

  final String? uri;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(uri);
    final radius = size / 2;

    if (resolved != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(radius),
          errorWidget: (_, __, ___) => _placeholder(radius),
        ),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandBlueLight,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Icon(Icons.person, size: size * 0.45, color: AppColors.specCircleFill),
    );
  }
}
