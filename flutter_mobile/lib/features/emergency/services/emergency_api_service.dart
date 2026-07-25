import '../../../config/api_config.dart';
import '../../../services/api_service.dart';
import '../models/emergency_case_model.dart';
import '../models/emergency_contact_model.dart';

class _BackendContact {
  const _BackendContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation,
  });

  final int id;
  final String name;
  final String phone;
  final String? relation;

  static _BackendContact? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) return null;
    final parsedId = id is int ? id : int.tryParse('$id');
    if (parsedId == null) return null;
    return _BackendContact(
      id: parsedId,
      name: '${json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      relation: json['relation']?.toString(),
    );
  }
}

/// Backend sync for emergency contacts and SOS audit log (when logged in).
class EmergencyApiService {
  EmergencyApiService(this._api);

  final ApiService _api;

  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  Future<List<EmergencyContactModel>> fetchContacts() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.userEmergencyContacts);
    final data = res.data ?? {};
    if (data['success'] != true) return [];
    final contacts = data['contacts'];
    if (contacts is! Map) return [];

    final out = <EmergencyContactModel>[];
    for (final bucket in contacts.values) {
      if (bucket is! List) continue;
      for (final raw in bucket) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final name = '${map['name'] ?? ''}'.trim();
        final phone = '${map['phone'] ?? ''}'.trim();
        if (name.isEmpty || phone.isEmpty) continue;
        out.add(EmergencyContactModel(
          name: name,
          phone: phone,
          relation: map['relation']?.toString(),
        ));
      }
    }
    return out;
  }

  Future<void> syncContacts(List<EmergencyContactModel> localContacts) async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.userEmergencyContacts);
    final data = res.data ?? {};
    if (data['success'] != true) return;

    final existing = <_BackendContact>[];
    final contacts = data['contacts'];
    if (contacts is Map) {
      for (final bucket in contacts.values) {
        if (bucket is! List) continue;
        for (final raw in bucket) {
          if (raw is Map) {
            final parsed = _BackendContact.fromJson(Map<String, dynamic>.from(raw));
            if (parsed != null) existing.add(parsed);
          }
        }
      }
    }

    for (final local in localContacts) {
      if (!local.isValid) continue;
      final localDigits = _normalizePhone(local.phone);
      _BackendContact? match;
      for (final e in existing) {
        if (_normalizePhone(e.phone) == localDigits) {
          match = e;
          break;
        }
      }

      if (match != null) {
        await _api.post<Map<String, dynamic>>(
          ApiConfig.userEmergencyContactUpdate,
          data: {
            'contactId': match.id,
            'name': local.name.trim(),
            'phone': local.phone.trim(),
            'relation': local.relation?.trim() ?? match.relation ?? '',
            'contact_type': 'family',
          },
        );
      } else {
        await _api.post<Map<String, dynamic>>(
          ApiConfig.userEmergencyContactAdd,
          data: {
            'name': local.name.trim(),
            'phone': local.phone.trim(),
            'relation': local.relation?.trim() ?? '',
            'contact_type': 'family',
          },
        );
      }
    }
  }

  Future<void> logSosEvent(EmergencyCaseModel caseModel) async {
    try {
      await _api.post<Map<String, dynamic>>(
        ApiConfig.emergencyLogEvent,
        data: {
          'eventType': 'sos_activated',
          'severity': caseModel.severity.name,
          'triggerType': caseModel.triggerType.name,
          'symptoms': caseModel.symptoms,
          'latitude': caseModel.latitude,
          'longitude': caseModel.longitude,
          'mapsLink': caseModel.mapsLink,
          'isHelperFlow': caseModel.isHelperFlow,
          'notes': caseModel.notes,
          'source': 'flutter',
        },
      );
    } catch (_) {
      // SOS must not fail if audit logging is unavailable
    }
  }
}
