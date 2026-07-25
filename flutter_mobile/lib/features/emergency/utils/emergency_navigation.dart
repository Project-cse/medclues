import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../routes/route_names.dart';
import '../providers/emergency_provider.dart';

/// Leave emergency module — dashboard if logged in, login if not.
void exitEmergencyToHome(BuildContext context, WidgetRef ref, {bool clearSession = true}) {
  if (clearSession) {
    ref.read(emergencySessionProvider.notifier).clear();
  }
  final auth = ref.read(authProvider);
  final dest = auth.status == AuthStatus.authenticated ? RouteNames.dashboard : RouteNames.login;
  context.go(dest);
}
