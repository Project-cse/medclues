import 'emergency_contact_model.dart';

class EmergencySettingsModel {
  const EmergencySettingsModel({
    this.relativeContact1,
    this.relativeContact2,
    this.bloodGroup,
    this.allergies,
    this.existingDiseases,
    this.currentMedications,
    this.autoSosTimerSeconds = 30,
    this.voiceSosEnabled = false,
    this.tripleTapSosEnabled = false,
    this.shakeSosEnabled = false,
    this.autoLocationSharing = true,
  });

  final EmergencyContactModel? relativeContact1;
  final EmergencyContactModel? relativeContact2;
  final String? bloodGroup;
  final String? allergies;
  final String? existingDiseases;
  final String? currentMedications;
  final int autoSosTimerSeconds;
  final bool voiceSosEnabled;
  final bool tripleTapSosEnabled;
  final bool shakeSosEnabled;
  final bool autoLocationSharing;

  List<EmergencyContactModel> get savedContacts {
    return [
      if (relativeContact1?.isValid == true) relativeContact1!,
      if (relativeContact2?.isValid == true) relativeContact2!,
    ];
  }

  EmergencySettingsModel copyWith({
    EmergencyContactModel? relativeContact1,
    EmergencyContactModel? relativeContact2,
    String? bloodGroup,
    String? allergies,
    String? existingDiseases,
    String? currentMedications,
    int? autoSosTimerSeconds,
    bool? voiceSosEnabled,
    bool? tripleTapSosEnabled,
    bool? shakeSosEnabled,
    bool? autoLocationSharing,
    bool clearContact1 = false,
    bool clearContact2 = false,
  }) {
    return EmergencySettingsModel(
      relativeContact1: clearContact1 ? null : (relativeContact1 ?? this.relativeContact1),
      relativeContact2: clearContact2 ? null : (relativeContact2 ?? this.relativeContact2),
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      existingDiseases: existingDiseases ?? this.existingDiseases,
      currentMedications: currentMedications ?? this.currentMedications,
      autoSosTimerSeconds: autoSosTimerSeconds ?? this.autoSosTimerSeconds,
      voiceSosEnabled: voiceSosEnabled ?? this.voiceSosEnabled,
      tripleTapSosEnabled: tripleTapSosEnabled ?? this.tripleTapSosEnabled,
      shakeSosEnabled: shakeSosEnabled ?? this.shakeSosEnabled,
      autoLocationSharing: autoLocationSharing ?? this.autoLocationSharing,
    );
  }

  Map<String, dynamic> toJson() => {
        'relativeContact1': relativeContact1?.toJson(),
        'relativeContact2': relativeContact2?.toJson(),
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'existingDiseases': existingDiseases,
        'currentMedications': currentMedications,
        'autoSosTimerSeconds': autoSosTimerSeconds,
        'voiceSosEnabled': voiceSosEnabled,
        'tripleTapSosEnabled': tripleTapSosEnabled,
        'shakeSosEnabled': shakeSosEnabled,
        'autoLocationSharing': autoLocationSharing,
      };

  factory EmergencySettingsModel.fromJson(Map<String, dynamic> json) {
    EmergencyContactModel? contact(dynamic raw) {
      if (raw is Map<String, dynamic>) return EmergencyContactModel.fromJson(raw);
      return null;
    }

    return EmergencySettingsModel(
      relativeContact1: contact(json['relativeContact1']),
      relativeContact2: contact(json['relativeContact2']),
      bloodGroup: json['bloodGroup']?.toString(),
      allergies: json['allergies']?.toString(),
      existingDiseases: json['existingDiseases']?.toString(),
      currentMedications: json['currentMedications']?.toString(),
      autoSosTimerSeconds: json['autoSosTimerSeconds'] as int? ?? 30,
      voiceSosEnabled: json['voiceSosEnabled'] == true,
      tripleTapSosEnabled: json['tripleTapSosEnabled'] == true,
      shakeSosEnabled: json['shakeSosEnabled'] == true,
      autoLocationSharing: json['autoLocationSharing'] != false,
    );
  }
}
