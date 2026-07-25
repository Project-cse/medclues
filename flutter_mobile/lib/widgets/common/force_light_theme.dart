import 'package:flutter/material.dart';

import '../../themes/app_theme.dart';

/// Forces light theme — used for auth (login/signup) and emergency/SOS screens.
class ForceLightTheme extends StatelessWidget {
  const ForceLightTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: child,
    );
  }
}
