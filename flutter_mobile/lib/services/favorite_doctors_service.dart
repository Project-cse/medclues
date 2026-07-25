import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite doctor IDs locally.
class FavoriteDoctorsService {
  static const _key = '@pms/favorite_doctors';

  Future<Set<String>> loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => '$e').where((id) => id.isNotEmpty).toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<Set<String>> toggle(String doctorId) async {
    final ids = await loadIds();
    if (ids.contains(doctorId)) {
      ids.remove(doctorId);
    } else {
      ids.add(doctorId);
    }
    await _save(ids);
    return ids;
  }

  Future<bool> isFavorite(String doctorId) async {
    final ids = await loadIds();
    return ids.contains(doctorId);
  }

  Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }
}
