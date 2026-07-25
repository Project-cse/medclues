import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'medclues_palette.dart';

/// Seamless splash → login structural handoff — logo Hero flies up, form rises.
class MedcluesLoginTransition {
  static CustomTransitionPage<T> page<T>({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: transitionsBuilder,
    );
  }

  static Widget transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final logoEase = CurvedAnimation(
      parent: animation,
      curve: MedcluesPalette.emphasized,
    );
    final formEase = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
    );
    final fadeSecondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeIn,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(fadeSecondary),
          child: const ColoredBox(color: MedcluesPalette.pureWhite),
        ),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(formEase),
          child: FadeTransition(
            opacity: formEase,
            child: child,
          ),
        ),
        IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              Tween<double>(begin: 1, end: 0).animate(
                CurvedAnimation(parent: animation, curve: const Interval(0, 0.5)),
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
        // Hero handles logo flight; this layer only softens background jitter.
        FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(logoEase),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
