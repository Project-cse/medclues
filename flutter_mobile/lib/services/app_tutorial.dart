import 'package:flutter/material.dart';

import '../helpers/storage_helper.dart';
import '../models/tutorial_step.dart';
import '../widgets/tutorial/app_tutorial_overlay.dart';

abstract final class AppTutorial {
  static const _medicalBlue = Color(0xFF003B8E);
  static const _actionBlue = Color(0xFF2563EB);

  static List<TutorialStep> onboardingSteps() => const [
        TutorialStep(
          title: 'Welcome to MEDCLUES',
          body: 'Your premium healthcare companion — book doctors, find hospitals, and manage health records securely.',
          icon: Icons.medical_services_rounded,
        ),
        TutorialStep(
          title: 'Search & discover',
          body: 'Use the search bar to find doctors, hospitals, labs, and specialities in seconds.',
          icon: Icons.search_rounded,
        ),
        TutorialStep(
          title: 'Partner hospitals',
          body: 'Browse verified hospitals, filter by nearby location, and book appointments with trusted care providers.',
          icon: Icons.local_hospital_rounded,
        ),
        TutorialStep(
          title: 'Appointments & records',
          body: 'Track upcoming visits from Appointments. Store and share medical documents safely in Records.',
          icon: Icons.folder_open_rounded,
        ),
        TutorialStep(
          title: 'Emergency support',
          body: 'Quick access to emergency help and location sharing when every second matters.',
          icon: Icons.emergency_rounded,
        ),
      ];

  static List<TutorialStep> doctorProfileSteps({
    required GlobalKey videoKey,
    required GlobalKey shareKey,
  }) =>
      [
        TutorialStep(
          title: 'Video consultation',
          body: 'Tap Video to book an online consult — speak with your doctor from home.',
          icon: Icons.videocam_rounded,
          targetKey: videoKey,
          highlightLabel: 'Tap here',
        ),
        TutorialStep(
          title: 'Share with family',
          body: 'Tap Share to send this doctor\'s details to a caregiver or family member.',
          icon: Icons.share_rounded,
          targetKey: shareKey,
          highlightLabel: 'Tap here',
        ),
      ];

  /// Legacy full-screen card carousel. Prefer [OnboardingManager] soft tour.
  /// Kept for optional doctor-profile tips only — do not use for first-run onboarding.
  static Future<void> showOnboarding(
    BuildContext context,
    StorageHelper storage, {
    required String userId,
  }) {
    return AppTutorialOverlay.show(
      context,
      steps: onboardingSteps(),
      accentColor: _medicalBlue,
      onFinished: () => storage.setOnboardingCompletedFor(userId, true),
    );
  }

  static Future<void> showDoctorProfile(
    BuildContext context,
    StorageHelper storage, {
    required String userId,
    required GlobalKey videoKey,
    required GlobalKey shareKey,
  }) {
    return AppTutorialOverlay.show(
      context,
      steps: doctorProfileSteps(videoKey: videoKey, shareKey: shareKey),
      accentColor: _actionBlue,
      onFinished: () async {
        await storage.setDoctorProfileTutorialSeenFor(userId, true);
        await storage.clearPendingNewUser(userId);
      },
    );
  }
}
