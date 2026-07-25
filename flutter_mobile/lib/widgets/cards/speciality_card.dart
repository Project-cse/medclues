import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/speciality_assets.dart';
import '../../constants/home_specialities.dart';
import '../../models/speciality_model.dart';
import '../home/premium_speciality_card.dart';

class SpecialityCard extends StatelessWidget {
  const SpecialityCard({
    super.key,
    required this.speciality,
    this.selected = false,
  });

  final SpecialityModel speciality;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final asset = SpecialityAssets.assetPathFor(speciality.name) ?? '';
    final item = HomeSpeciality(
      name: speciality.name,
      filterKey: speciality.name,
      assetPath: asset,
    );

    return PremiumSpecialityCard(
      item: item,
      selected: selected,
      onTap: () => context.push(
        '/doctors?speciality=${Uri.encodeComponent(speciality.name)}',
      ),
    );
  }
}
