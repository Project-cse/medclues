import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

abstract final class EmergencyConstants {
  /// When true, ambulance/police/fire tel: calls are blocked (testing only).
  /// Release builds: false (real calls). Debug: true unless overridden.
  /// Override: `--dart-define=EMERGENCY_TESTING=true|false`
  static bool get testingMode {
    const override = String.fromEnvironment('EMERGENCY_TESTING');
    if (override == 'true') return true;
    if (override == 'false') return false;
    return kDebugMode;
  }

  static const ambulance = '108';
  static const police = '100';
  static const policeAlt = '112';
  static const fire = '101';

  static const defaultTimerSeconds = 30;

  static const criticalSymptoms = {
    'Chest Pain',
    'Breathing Difficulty',
    'Heavy Bleeding',
    'Accident',
    'Stroke Symptoms',
  };

  static const moderateSymptoms = {'Severe Pain', 'Fever'};

  static const minorSymptoms = {'Other'};

  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedDark = Color(0xFFB91C1C);
  static const Color emergencyBg = Color(0xFFFFF1F2);
  static const Color emergencyText = AppColors.textPrimary;
}
