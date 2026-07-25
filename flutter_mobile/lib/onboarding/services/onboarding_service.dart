import '../../config/api_config.dart';
import '../../constants/profile_options.dart';
import '../../models/patient_model.dart';
import '../../services/api_service.dart';
import '../../utils/json_parser.dart';
import '../models/onboarding_status.dart';

class OnboardingService {
  OnboardingService(this._api);

  final ApiService _api;

  Future<Map<String, dynamic>> _fetchUserJson() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.userProfile);
    final data = res.data ?? {};
    assertSuccess(data);
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    if (user == null) throw Exception('Profile unavailable');
    return user;
  }

  Future<OnboardingStatus> fetchStatus() async {
    final user = await _fetchUserJson();
    return _resolveFromUser(OnboardingStatus.fromJson(user), user);
  }

  /// Sync flags with real profile + emergency contact data.
  Future<OnboardingStatus> _resolveFromUser(OnboardingStatus status, Map<String, dynamic> user) async {
    var resolved = status;
    if (!resolved.emergencyContactCompleted) {
      final has = _hasContactsInUser(user) || await hasEmergencyContacts();
      if (has) resolved = resolved.copyWith(emergencyContactCompleted: true);
    }
    if (!resolved.profileCompleted && _isProfileComplete(user)) {
      resolved = resolved.copyWith(profileCompleted: true);
    }
    return resolved;
  }

  bool _hasContactsInUser(Map<String, dynamic> user) {
    final raw = user['emergencyContacts'];
    if (raw is Map) {
      for (final v in raw.values) {
        if (v is List && v.isNotEmpty) return true;
      }
    }
    return false;
  }

  Future<bool> hasEmergencyContacts() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiConfig.userEmergencyContacts);
      final data = res.data ?? {};
      if (data['success'] != true) return false;
      final contacts = data['contacts'];
      if (contacts is Map) {
        for (final v in contacts.values) {
          if (v is List && v.isNotEmpty) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  bool _isProfileComplete(Map<String, dynamic> user) {
    final name = '${user['name'] ?? ''}'.trim();
    final phone = ProfileOptions.sanitize(user['phone']?.toString());
    final gender = ProfileOptions.normalizeGender(user['gender']?.toString());
    final blood = ProfileOptions.normalizeBloodGroup(user['bloodGroup']?.toString());
    final dob = ProfileOptions.sanitize(user['dob']?.toString());
    return name.isNotEmpty &&
        phone != null &&
        gender != null &&
        blood != null &&
        dob != null;
  }

  Future<OnboardingStatus> saveStatus(OnboardingStatus status) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiConfig.userOnboarding,
      data: status.toPatchJson(),
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Failed to save onboarding');
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    if (user == null) return status;
    return _resolveFromUser(OnboardingStatus.fromJson(user), user);
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userEmergencyContactAdd,
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'relation': relation.trim(),
        'contact_type': 'family',
      },
    );
    assertSuccess(res.data ?? {}, 'Failed to save emergency contact');
  }

  /// Sends a 6-digit verification code to the user's email.
  /// Returns a dev OTP string when the backend is in debug mode and email
  /// delivery failed (null otherwise).
  Future<String?> sendEmailVerification() async {
    final res = await _api.post<Map<String, dynamic>>(ApiConfig.userSendEmailVerification);
    final data = res.data ?? {};
    assertSuccess(data, 'Failed to send verification code');
    return data['dev_otp']?.toString();
  }

  Future<void> verifyEmail(String otp) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userVerifyEmail,
      data: {'otp': otp.trim()},
    );
    assertSuccess(res.data ?? {}, 'Invalid code');
  }

  Future<PatientModel> updateProfile(PatientModel patient) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiConfig.userPatchProfile,
      data: patient.toPatchJson(),
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Profile update failed');
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    if (user == null) throw Exception('Profile update failed');
    return PatientModel.fromJson(user);
  }
}
