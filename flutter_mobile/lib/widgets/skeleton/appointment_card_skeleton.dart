import 'package:flutter/material.dart';

import 'list_card_skeleton.dart';

class AppointmentCardSkeleton extends StatelessWidget {
  const AppointmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListCardSkeleton(
      height: 120,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}
