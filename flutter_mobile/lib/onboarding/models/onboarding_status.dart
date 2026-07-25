class OnboardingStatus {
  const OnboardingStatus({
    this.onboardingCompleted = false,
    this.tutorialCompleted = false,
    this.emergencyContactCompleted = false,
    this.profileCompleted = false,
    this.onboardingStep = 0,
  });

  final bool onboardingCompleted;
  final bool tutorialCompleted;
  final bool emergencyContactCompleted;
  final bool profileCompleted;
  final int onboardingStep;

  bool get needsOnboarding => !onboardingCompleted;

  /// 0–2 soft tour, then required setup, then done
  int get resumeStep {
    if (onboardingCompleted) return 5;
    if (!tutorialCompleted) {
      return onboardingStep.clamp(0, onboardingTourStepCount - 1);
    }
    if (!emergencyContactCompleted || !profileCompleted) return 3;
    return 4;
  }

  /// Soft-tour length (must match [onboardingTourSteps].length).
  static const onboardingTourStepCount = 3;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      onboardingCompleted: json['onboardingCompleted'] == true,
      tutorialCompleted: json['tutorialCompleted'] == true,
      emergencyContactCompleted: json['emergencyContactCompleted'] == true,
      profileCompleted: json['profileCompleted'] == true,
      onboardingStep: json['onboardingStep'] is int
          ? json['onboardingStep'] as int
          : int.tryParse('${json['onboardingStep'] ?? 0}') ?? 0,
    );
  }

  OnboardingStatus copyWith({
    bool? onboardingCompleted,
    bool? tutorialCompleted,
    bool? emergencyContactCompleted,
    bool? profileCompleted,
    int? onboardingStep,
  }) {
    return OnboardingStatus(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      emergencyContactCompleted: emergencyContactCompleted ?? this.emergencyContactCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }

  Map<String, dynamic> toPatchJson() => {
        if (onboardingCompleted) 'onboardingCompleted': true,
        'tutorialCompleted': tutorialCompleted,
        'emergencyContactCompleted': emergencyContactCompleted,
        'profileCompleted': profileCompleted,
        'onboardingStep': onboardingStep,
      };
}
