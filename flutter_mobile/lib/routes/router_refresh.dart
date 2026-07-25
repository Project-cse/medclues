import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

/// Notifies GoRouter when auth changes without recreating the router instance.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<OnboardingUiState>(onboardingProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
