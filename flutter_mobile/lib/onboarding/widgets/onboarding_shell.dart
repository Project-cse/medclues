import 'package:flutter/material.dart';

/// Provides a [Navigator] so dialogs, date pickers, and sheets work on web.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => child),
    );
  }
}
