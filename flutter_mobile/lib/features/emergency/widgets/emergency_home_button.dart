import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/emergency_navigation.dart';

class EmergencyHomeButton extends ConsumerWidget {
  const EmergencyHomeButton({
    super.key,
    this.onBeforeExit,
    this.clearSession = true,
  });

  final VoidCallback? onBeforeExit;
  final bool clearSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.home_rounded),
      tooltip: 'Home',
      onPressed: () {
        onBeforeExit?.call();
        exitEmergencyToHome(context, ref, clearSession: clearSession);
      },
    );
  }
}
