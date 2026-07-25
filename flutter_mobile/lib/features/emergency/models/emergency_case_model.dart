enum EmergencyTriggerType {
  timerAutoSos,
  criticalButton,
  symptomCritical,
  symptomModerate,
  symptomMinor,
  helperCritical,
  helperModerate,
  helperMinor,
}

enum EmergencySeverity { critical, moderate, minor }

class EmergencyCaseModel {
  const EmergencyCaseModel({
    required this.id,
    required this.createdAt,
    required this.triggerType,
    required this.severity,
    this.symptoms = const [],
    this.latitude,
    this.longitude,
    this.mapsLink,
    this.isHelperFlow = false,
    this.notes,
  });

  final String id;
  final DateTime createdAt;
  final EmergencyTriggerType triggerType;
  final EmergencySeverity severity;
  final List<String> symptoms;
  final double? latitude;
  final double? longitude;
  final String? mapsLink;
  final bool isHelperFlow;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'triggerType': triggerType.name,
        'severity': severity.name,
        'symptoms': symptoms,
        'latitude': latitude,
        'longitude': longitude,
        'mapsLink': mapsLink,
        'isHelperFlow': isHelperFlow,
        'notes': notes,
      };

  factory EmergencyCaseModel.fromJson(Map<String, dynamic> json) {
    return EmergencyCaseModel(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      triggerType: EmergencyTriggerType.values.firstWhere(
        (e) => e.name == json['triggerType'],
        orElse: () => EmergencyTriggerType.criticalButton,
      ),
      severity: EmergencySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => EmergencySeverity.critical,
      ),
      symptoms: (json['symptoms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapsLink: json['mapsLink']?.toString(),
      isHelperFlow: json['isHelperFlow'] == true,
      notes: json['notes']?.toString(),
    );
  }
}
