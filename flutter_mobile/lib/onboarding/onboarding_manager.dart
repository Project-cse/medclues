import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/emergency/providers/emergency_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/route_names.dart';
import '../widgets/healthcare/premium_healthcare_theme.dart';
import 'onboarding_tour_steps.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/onboarding_complete_step.dart';
import 'widgets/onboarding_setup_step.dart';
import 'widgets/onboarding_shell.dart';
import 'widgets/onboarding_spotlight.dart';

/// Wraps the app and drives first-time onboarding:
/// Phase A — soft 3-step home tour (skippable)
/// Phase B — required profile + emergency contact setup
class OnboardingManager extends ConsumerStatefulWidget {
  const OnboardingManager({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnboardingManager> createState() => _OnboardingManagerState();
}

class _OnboardingManagerState extends ConsumerState<OnboardingManager> {
  int? _syncedTourIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      ref.read(onboardingProvider.notifier).load();
    }
  }

  /// Keep user on the tour step route (Home for all soft-tour steps).
  void _navigateToTourStep(int tourIndex) {
    final step = onboardingTourSteps[tourIndex.clamp(0, onboardingTourSteps.length - 1)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = GoRouterState.of(context).matchedLocation;
      if (loc != step.route) {
        context.go(step.route);
      }
    });
  }

  static const _preAppRoutes = {
    RouteNames.splash,
    RouteNames.login,
    RouteNames.signup,
    RouteNames.forgotPassword,
    RouteNames.permissionsSetup,
  };

  bool _isPreAppRoute(BuildContext context) {
    try {
      return _preAppRoutes.contains(GoRouterState.of(context).matchedLocation);
    } catch (_) {
      return false;
    }
  }

  Widget _blockingScreen(Widget page) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: PremiumHealthcareTheme.background(context),
            child: OnboardingShell(child: page),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingProvider);

    ref.listen<OnboardingUiState>(onboardingProvider, (prev, next) {
      if (next.phase != OnboardingPhase.tour) {
        _syncedTourIndex = null;
        return;
      }
      if (prev?.tourIndex != next.tourIndex || _syncedTourIndex == null) {
        _syncedTourIndex = next.tourIndex;
        _navigateToTourStep(next.tourIndex);
      }
    });

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated && prev?.status != AuthStatus.authenticated) {
        ref.read(onboardingProvider.notifier).load();
        ref.read(emergencySettingsProvider.notifier).syncRemoteContactsFromApi();
      }
    });

    final auth = ref.watch(authProvider);
    if (auth.status != AuthStatus.authenticated) {
      return widget.child;
    }

    if (_isPreAppRoute(context)) {
      return widget.child;
    }

    if (ob.phase == OnboardingPhase.loading) {
      return Stack(
        children: [
          widget.child,
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white70,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      );
    }

    // Phase B — required setup (no skip).
    if (ob.phase == OnboardingPhase.setup) {
      return _blockingScreen(const OnboardingSetupStep());
    }
    if (ob.phase == OnboardingPhase.complete || ob.showCompletion) {
      return _blockingScreen(const OnboardingCompleteStep());
    }

    // Phase A — soft tour (skippable).
    if (ob.phase == OnboardingPhase.tour && ob.needsOnboarding) {
      final step = onboardingTourSteps[ob.tourIndex.clamp(0, onboardingTourSteps.length - 1)];
      final isLast = ob.tourIndex >= onboardingTourSteps.length - 1;
      final tourTotal = onboardingTourSteps.length;
      return Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: OnboardingSpotlight(
              key: ValueKey('tour-${step.index}'),
              step: step,
              totalSteps: tourTotal,
              canGoBack: ob.tourIndex > 0,
              isLastTourStep: isLast,
              onNext: () => ref.read(onboardingProvider.notifier).nextTourStep(),
              onPrevious: () => ref.read(onboardingProvider.notifier).previousTourStep(),
              onSkip: () => ref.read(onboardingProvider.notifier).skipTour(),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
