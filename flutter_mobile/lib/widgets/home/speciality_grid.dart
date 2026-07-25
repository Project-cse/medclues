import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/home_specialities.dart';
import 'premium_speciality_card.dart';
import 'premium_speciality_theme.dart';

/// 4 × 3 premium specialty grid — pixel-aligned, fixed card sizes.
class SpecialityGrid extends StatefulWidget {
  const SpecialityGrid({
    super.key,
    this.selectedFilterKey,
    this.onSpecialityTap,
  });

  /// Highlights the card matching this filter key (e.g. from doctors screen).
  final String? selectedFilterKey;
  final void Function(HomeSpeciality item)? onSpecialityTap;

  @override
  State<SpecialityGrid> createState() => _SpecialityGridState();
}

class _SpecialityGridState extends State<SpecialityGrid> {
  String? _localSelected;

  static const int _columns = 4;
  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    final items = homeSpecialities.take(_columns * _rows).toList();
    final activeKey = widget.selectedFilterKey ?? _localSelected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - PremiumSpecialityTheme.horizontalMargin * 2;
        final gap = PremiumSpecialityTheme.gridGap;
        final cellWidth = (gridWidth - gap * (_columns - 1)) / _columns;

        const iconSize = PremiumSpecialityTheme.iconSize;
        const labelH = PremiumSpecialityTheme.labelHeight;
        final cellHeight = iconSize + 8 + labelH;
        final aspectRatio = cellWidth / cellHeight;

        final iconDisplay = cellWidth >= 72 ? iconSize : cellWidth.clamp(44.0, iconSize);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PremiumSpecialityTheme.horizontalMargin,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = activeKey != null &&
                  activeKey.toLowerCase() == item.filterKey.toLowerCase();

              return PremiumSpecialityCard(
                item: item,
                selected: selected,
                iconSize: iconDisplay,
                onTap: () {
                  setState(() => _localSelected = item.filterKey);
                  if (widget.onSpecialityTap != null) {
                    widget.onSpecialityTap!(item);
                  } else {
                    context.push(
                      '/doctors?speciality=${Uri.encodeComponent(item.filterKey)}',
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
