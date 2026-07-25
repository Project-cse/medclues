import '../config/api_config.dart';
import '../models/saved_profile.dart';
import 'api_service.dart';

class SavedProfileService {
  const SavedProfileService(this._api);

  final ApiService _api;

  Future<List<SavedProfile>> fetchAll() async {
    final response =
        await _api.get<Map<String, dynamic>>(ApiConfig.savedProfiles);
    final data = response.data ?? const <String, dynamic>{};
    _assertSuccess(data);
    final raw = data['profiles'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => SavedProfile.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> create(Map<String, dynamic> profile) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConfig.saveProfile,
      data: profile,
    );
    _assertSuccess(response.data ?? const <String, dynamic>{});
  }

  Future<void> update(String id, Map<String, dynamic> profile) async {
    final response = await _api.put<Map<String, dynamic>>(
      ApiConfig.savedProfile(id),
      data: profile,
    );
    _assertSuccess(response.data ?? const <String, dynamic>{});
  }

  Future<void> delete(String id) async {
    final response = await _api.delete<Map<String, dynamic>>(
      ApiConfig.savedProfile(id),
    );
    _assertSuccess(response.data ?? const <String, dynamic>{});
  }

  void _assertSuccess(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw Exception(
          data['message']?.toString() ?? 'Saved profile request failed');
    }
  }
}
