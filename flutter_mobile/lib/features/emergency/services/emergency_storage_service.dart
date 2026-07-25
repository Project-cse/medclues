import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_case_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/emergency_settings_model.dart';

/// Local-only emergency data — works without login or backend.
class EmergencyStorageService {
  static const _settingsKey = 'emergency_settings_v1';
  static const _casesKey = 'emergency_cases_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _sp() async => _prefs ??= await SharedPreferences.getInstance();

  Future<EmergencySettingsModel> loadSettings() async {
    final raw = (await _sp()).getString(_settingsKey);
    if (raw == null || raw.isEmpty) return const EmergencySettingsModel();
    try {
      return EmergencySettingsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const EmergencySettingsModel();
    }
  }

  Future<void> saveSettings(EmergencySettingsModel settings) async {
    await (await _sp()).setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<EmergencyCaseModel>> loadCases() async {
    final raw = (await _sp()).getString(_casesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(EmergencyCaseModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCase(EmergencyCaseModel caseModel) async {
    final cases = await loadCases();
    cases.insert(0, caseModel);
    final trimmed = cases.take(50).toList();
    await (await _sp()).setString(
      _casesKey,
      jsonEncode(trimmed.map((c) => c.toJson()).toList()),
    );
  }

  /// Returns null when both name and phone are empty.
  /// Throws [ArgumentError] when only one of name/phone is filled.
  EmergencyContactModel? parseContact(String name, String phone, String relation) {
    final n = name.trim();
    final p = phone.trim();
    final r = relation.trim();

    if (n.isEmpty && p.isEmpty) return null;
    if (n.isEmpty || p.isEmpty) {
      throw ArgumentError('Contact needs both name and phone number');
    }

    return EmergencyContactModel(
      name: n,
      phone: p,
      relation: r.isEmpty ? null : r,
    );
  }
}
