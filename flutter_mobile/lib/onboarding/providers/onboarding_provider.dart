import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../models/onboarding_status.dart';
import '../onboarding_tour_steps.dart';
import '../services/onboarding_service.dart';

enum OnboardingPhase { loading, tour, setup, complete, done }

class OnboardingUiState {
  const OnboardingUiState({
    this.phase = OnboardingPhase.loading,
    this.status = const OnboardingStatus(),
    this.tourIndex = 0,
    this.showCompletion = false,
    this.error,
  });

  final OnboardingPhase phase;
  final OnboardingStatus status;
  final int tourIndex;
  final bool showCompletion;
  final String? error;

  bool get needsOnboarding => !status.onboardingCompleted;

  OnboardingUiState copyWith({
    OnboardingPhase? phase,
    OnboardingStatus? status,
    int? tourIndex,
    bool? showCompletion,
    String? error,
  }) {
    return OnboardingUiState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      tourIndex: tourIndex ?? this.tourIndex,
      showCompletion: showCompletion ?? this.showCompletion,
      error: error,
    );
  }
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref.watch(apiServiceProvider));
});

class OnboardingNotifier extends StateNotifier<OnboardingUiState> {
  OnboardingNotifier(this._ref) : super(const OnboardingUiState());

  final Ref _ref;

  OnboardingService get _service => _ref.read(onboardingServiceProvider);

  OnboardingPhase _phaseFor(OnboardingStatus status) {
    if (!status.tutorialCompleted) return OnboardingPhase.tour;
    // Emergency contact + profile are collected together on one robust screen.
    if (!status.emergencyContactCompleted || !status.profileCompleted) {
      return OnboardingPhase.setup;
    }
    return OnboardingPhase.complete;
  }

  Future<void> load() async {
    // Never regress a locally finished onboarding back to setup/loading because
    // a slow saveStatus race still reports needsOnboarding on the server.
    final alreadyDone =
        state.phase == OnboardingPhase.done && state.status.onboardingCompleted;
    if (!alreadyDone) {
      state = state.copyWith(phase: OnboardingPhase.loading, error: null);
    }
    try {
      final status = await _service
          .fetchStatus()
          .timeout(const Duration(seconds: 12));
      if (alreadyDone) {
        if (!status.needsOnboarding) {
          state = OnboardingUiState(phase: OnboardingPhase.done, status: status);
        }
        return;
      }
      if (!status.needsOnboarding) {
        state = OnboardingUiState(phase: OnboardingPhase.done, status: status);
        return;
      }
      final tourIndex = status.tutorialCompleted
          ? onboardingTourSteps.length
          : status.onboardingStep.clamp(0, onboardingTourSteps.length - 1);
      final phase = _phaseFor(status);
      state = OnboardingUiState(
        phase: phase,
        status: status,
        tourIndex: tourIndex,
        showCompletion: status.profileCompleted && !status.onboardingCompleted,
      );
    } catch (e) {
      if (alreadyDone) return;
      state = state.copyWith(phase: OnboardingPhase.done, error: e.toString());
    }
  }

  Future<void> _persist(OnboardingStatus status) async {
    final saved = await _service.saveStatus(status);
    state = state.copyWith(status: saved);
  }

  OnboardingPhase _nextPhaseFrom(OnboardingStatus status) {
    if (!status.emergencyContactCompleted || !status.profileCompleted) {
      return OnboardingPhase.setup;
    }
    return OnboardingPhase.complete;
  }

  /// Move to the next step using the given status as the source of truth.
  /// Always advances the UI instantly and persists to the server in the
  /// background, so a slow/cold backend can never freeze the flow.
  void _applyAdvance(OnboardingStatus status) {
    final phase = _nextPhaseFrom(status);
    state = state.copyWith(
      phase: phase,
      status: status,
      showCompletion: phase == OnboardingPhase.complete,
    );
    unawaited(_service.saveStatus(status).then((saved) {
      state = state.copyWith(status: saved);
    }).catchError((_) {}));
  }

  /// After tour ends — move forward immediately from local truth. The
  /// emergency/profile steps self-skip if their data already exists on the
  /// server, so there's no need to block here on a network round-trip.
  Future<void> _advanceAfterTour() async {
    _applyAdvance(state.status);
  }

  Future<void> goToTourIndex(int index) async {
    final clamped = index.clamp(0, onboardingTourSteps.length - 1);
    final nextStatus = state.status.copyWith(onboardingStep: clamped);
    state = state.copyWith(tourIndex: clamped, phase: OnboardingPhase.tour, status: nextStatus);
  }

  Future<void> nextTourStep() async {
    if (state.tourIndex >= onboardingTourSteps.length - 1) {
      await skipTour(markTutorialComplete: true);
      return;
    }
    await goToTourIndex(state.tourIndex + 1);
  }

  Future<void> previousTourStep() async {
    if (state.tourIndex <= 0) return;
    await goToTourIndex(state.tourIndex - 1);
  }

  Future<void> skipTour({bool markTutorialComplete = true}) async {
    final next = state.status.copyWith(
      tutorialCompleted: markTutorialComplete,
      onboardingStep: onboardingTourSteps.length,
    );
    state = state.copyWith(
      status: next,
      tourIndex: onboardingTourSteps.length,
    );
    // Persist in the background so leaving the last tour step is instant.
    unawaited(_persist(next).catchError((_) {}));
    await _advanceAfterTour();
  }

  /// Marks both the emergency contact and profile steps complete in one shot.
  /// The combined setup screen has already saved the data locally and kicked
  /// off background server syncs, so we advance to the welcome screen instantly
  /// and persist the onboarding flags in the background — this can never hang.
  Future<void> completeSetup() async {
    final next = state.status.copyWith(
      emergencyContactCompleted: true,
      profileCompleted: true,
      onboardingStep: 5,
    );
    state = state.copyWith(
      phase: OnboardingPhase.complete,
      status: next,
      showCompletion: true,
    );
    unawaited(_service.saveStatus(next).then((saved) {
      state = state.copyWith(status: saved);
    }).catchError((_) {}));
  }

  Future<void> finishOnboarding() async {
    final next = state.status.copyWith(
      onboardingCompleted: true,
      tutorialCompleted: true,
      emergencyContactCompleted: true,
      profileCompleted: true,
      onboardingStep: 5,
    );
    // Flip to "done" instantly so the UI advances to the home screen without
    // ever waiting on the network. Persist in the background with a retry.
    state = OnboardingUiState(phase: OnboardingPhase.done, status: next);
    try {
      await _service.saveStatus(next).timeout(const Duration(seconds: 8));
    } catch (_) {
      unawaited(_persistWithRetry(next));
    }
  }

  Future<void> _persistWithRetry(OnboardingStatus status, {int attempts = 3}) async {
    for (var i = 0; i < attempts; i++) {
      try {
        await _service.saveStatus(status);
        return;
      } catch (_) {
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
  }

  Future<void> resetForReplay() async {
    final reset = OnboardingStatus(
      onboardingCompleted: false,
      tutorialCompleted: false,
      emergencyContactCompleted: true,
      profileCompleted: true,
      onboardingStep: 0,
    );
    await _persist(reset);
    state = OnboardingUiState(phase: OnboardingPhase.tour, status: reset, tourIndex: 0);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingUiState>((ref) {
  return OnboardingNotifier(ref);
});
