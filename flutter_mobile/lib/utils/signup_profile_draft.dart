import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Temporary local cache of signup / social-login profile fields so the
/// required onboarding setup screen can pre-fill without waiting on a cold API.
class SignupProfileDraft {
  const SignupProfileDraft({
    this.name,
    this.email,
    this.phone,
    this.gender,
    this.dob,
    this.bloodGroup,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? gender;
  final String? dob;
  final String? bloodGroup;

  static const _key = 'medclues_signup_profile_draft_v1';

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (dob != null) 'dob': dob,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
      };

  factory SignupProfileDraft.fromJson(Map<String, dynamic> json) {
    return SignupProfileDraft(
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
    );
  }

  static Future<void> save(SignupProfileDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  static Future<SignupProfileDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return SignupProfileDraft.fromJson(map);
      if (map is Map) {
        return SignupProfileDraft.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
