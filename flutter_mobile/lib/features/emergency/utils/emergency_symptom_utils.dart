import '../emergency_constants.dart';
import '../models/emergency_case_model.dart';

EmergencySeverity classifySymptom(String symptom) {
  if (EmergencyConstants.criticalSymptoms.contains(symptom)) {
    return EmergencySeverity.critical;
  }
  if (EmergencyConstants.moderateSymptoms.contains(symptom)) {
    return EmergencySeverity.moderate;
  }
  return EmergencySeverity.minor;
}

EmergencyTriggerType triggerForSymptom(EmergencySeverity severity, {bool isHelper = false}) {
  if (isHelper) {
    switch (severity) {
      case EmergencySeverity.critical:
        return EmergencyTriggerType.helperCritical;
      case EmergencySeverity.moderate:
        return EmergencyTriggerType.helperModerate;
      case EmergencySeverity.minor:
        return EmergencyTriggerType.helperMinor;
    }
  }
  switch (severity) {
    case EmergencySeverity.critical:
      return EmergencyTriggerType.symptomCritical;
    case EmergencySeverity.moderate:
      return EmergencyTriggerType.symptomModerate;
    case EmergencySeverity.minor:
      return EmergencyTriggerType.symptomMinor;
  }
}

const allSymptoms = [
  'Chest Pain',
  'Breathing Difficulty',
  'Heavy Bleeding',
  'Accident',
  'Stroke Symptoms',
  'Severe Pain',
  'Fever',
  'Other',
];
