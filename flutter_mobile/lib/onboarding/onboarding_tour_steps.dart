import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../routes/route_names.dart';
import 'onboarding_tour_keys.dart';

/// Where the coach-mark tooltip should prefer to appear relative to the anchor.
enum TooltipPlacement { auto, above, below, left, right }

class OnboardingTarget {
  const OnboardingTarget({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.placement = TooltipPlacement.auto,
    this.anchorKey,
  });

  final double top;
  final double left;
  final double width;
  final double height;
  final double borderRadius;
  final TooltipPlacement placement;
  final GlobalKey? anchorKey;

  Rect? resolveInOverlay(BuildContext overlayContext) {
    final key = anchorKey;
    if (key == null) return null;
    return OnboardingTourKeys.rectInOverlay(key, overlayContext);
  }

  Rect fallbackRect(Size screen) => Rect.fromLTWH(
        screen.width * left,
        screen.height * top,
        screen.width * width,
        screen.height * height,
      );

  Rect rectFor(Size screen, {BuildContext? overlayContext}) {
    if (overlayContext != null) {
      final live = resolveInOverlay(overlayContext);
      if (live != null) return live;
    }
    return fallbackRect(screen);
  }
}

class OnboardingTourStep {
  const OnboardingTourStep({
    required this.index,
    required this.route,
    required this.title,
    required this.message,
    required this.icon,
    required this.target,
  });

  final int index;
  final String route;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) message;
  final IconData icon;
  final OnboardingTarget target;
}

/// Soft tour — 3 Home coach-marks (skippable).
final onboardingTourSteps = <OnboardingTourStep>[
  OnboardingTourStep(
    index: 1,
    route: RouteNames.dashboard,
    title: (l10n) => l10n.tourHomeTitle,
    message: (l10n) => l10n.tourHomeDesc,
    icon: Icons.search_rounded,
    target: OnboardingTarget(
      top: 0.11,
      left: 0.04,
      width: 0.92,
      height: 0.07,
      borderRadius: 14,
      placement: TooltipPlacement.below,
      anchorKey: OnboardingTourKeys.search,
    ),
  ),
  OnboardingTourStep(
    index: 2,
    route: RouteNames.dashboard,
    title: (l10n) => l10n.tourDoctorsTitle,
    message: (l10n) => l10n.tourDoctorsDesc,
    icon: Icons.medical_services_rounded,
    target: OnboardingTarget(
      top: 0.52,
      left: 0.26,
      width: 0.22,
      height: 0.12,
      borderRadius: 16,
      placement: TooltipPlacement.above,
      anchorKey: OnboardingTourKeys.doctors,
    ),
  ),
  OnboardingTourStep(
    index: 3,
    route: RouteNames.dashboard,
    title: (l10n) => l10n.tourEmergencyTitle,
    message: (l10n) => l10n.tourEmergencyDesc,
    icon: Icons.emergency_rounded,
    target: OnboardingTarget(
      top: 0.38,
      left: 0.04,
      width: 0.92,
      height: 0.08,
      borderRadius: 16,
      placement: TooltipPlacement.below,
      anchorKey: OnboardingTourKeys.emergency,
    ),
  ),
];
