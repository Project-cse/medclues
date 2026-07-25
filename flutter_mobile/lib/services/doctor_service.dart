import '../config/api_config.dart';
import '../models/doctor_model.dart';
import '../utils/json_parser.dart';
import '../utils/speciality_match.dart';
import 'api_service.dart';

class DoctorService {
  DoctorService(this._api);

  /// Max doctors shown in home "Top Doctors to Book".
  static const int homeTopDoctorLimit = 10;

  static const Duration _cacheTtl = Duration(minutes: 5);

  final ApiService _api;

  List<DoctorModel>? _cachedAll;
  DateTime? _cacheTime;
  int? _cachedHospitalId;

  void invalidateCache() {
    _cachedAll = null;
    _cacheTime = null;
    _cachedHospitalId = null;
  }

  DoctorModel? _fromCache(String id) {
    final list = _cachedAll;
    if (list == null) return null;
    for (final d in list) {
      if (d.id == id || d.id == id.toString()) return d;
    }
    return null;
  }

  Future<List<DoctorModel>> fetchAll({int? hospitalId, bool forceRefresh = false}) async {
    return fetchPage(hospitalId: hospitalId, forceRefresh: forceRefresh);
  }

  /// Server-paged doctor catalog (limit/offset/q). Falls back to merge of public lists.
  Future<List<DoctorModel>> fetchPage({
    int? hospitalId,
    bool forceRefresh = false,
    int limit = 100,
    int offset = 0,
    String? q,
  }) async {
    if (!forceRefresh &&
        q == null &&
        offset == 0 &&
        _cachedAll != null &&
        _cacheTime != null &&
        _cachedHospitalId == hospitalId &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl) {
      return _cachedAll!;
    }

    final seen = <String>{};
    final merged = <DoctorModel>[];

    void addFrom(dynamic responseData) {
      if (responseData is! Map<String, dynamic>) return;
      if (responseData['success'] == false) return;
      for (final raw in unwrapList(responseData, ['doctors'])) {
        final d = DoctorModel.fromJson(raw);
        if (seen.add(d.id)) merged.add(d);
      }
    }

    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (hospitalId != null) 'hospitalId': hospitalId,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };
    final results = await Future.wait<Map<String, dynamic>?>([
      _safeGet(ApiConfig.publicDoctors, queryParameters: params),
      _safeGet(ApiConfig.doctorList, queryParameters: params),
    ]);

    for (final data in results) {
      addFrom(data);
    }

    if (merged.isEmpty && results.every((r) => r == null)) {
      throw Exception('Failed to load doctors');
    }

    if (q == null && offset == 0) {
      _cachedAll = merged;
      _cacheTime = DateTime.now();
      _cachedHospitalId = hospitalId;
    }
    return merged;
  }

  Future<Map<String, dynamic>?> _safeGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(path, queryParameters: queryParameters);
      return res.data;
    } catch (_) {
      return null;
    }
  }

  Future<DoctorModel> fetchById(String id) async {
    // Prefer the detail endpoint first — it returns fully-joined data
    // (including the hospital name) that the cached list view can be missing.
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiConfig.doctorById(id));
      final data = res.data ?? {};
      assertSuccess(data);
      final doc = data['doctor'] as Map<String, dynamic>?;
      if (doc != null) {
        final model = DoctorModel.fromJson(doc);
        // If the detail row somehow lacks a hospital name, backfill from cache.
        if (model.hospitalName == null || model.hospitalName!.isEmpty) {
          final cached = _fromCache(id);
          if (cached?.hospitalName != null && cached!.hospitalName!.isNotEmpty) {
            return model.copyWith(hospitalName: cached.hospitalName);
          }
        }
        return model;
      }
    } catch (_) {
      /* fall through to cache / list lookup */
    }

    final cached = _fromCache(id);
    if (cached != null) return cached;

    final all = await fetchAll();
    return all.firstWhere(
      (d) => d.id == id || d.id == id.toString(),
      orElse: () => throw Exception('Doctor not found'),
    );
  }

  Future<List<DoctorModel>> search(String query, {String? speciality}) async {
    final all = await fetchAll();
    final q = query.trim().toLowerCase();
    var out = all;
    if (q.isNotEmpty) {
      out = out
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialization.toLowerCase().contains(q))
          .toList();
    }
    if (speciality != null && speciality.isNotEmpty) {
      final key = canonicalSpecialityKey(speciality) ?? speciality;
      out = out.where((d) => matchesSpeciality(d.specialization, key)).toList();
    }
    return out;
  }

  Future<List<DoctorModel>> fetchBySpeciality(String speciality) =>
      search('', speciality: speciality);

  Future<List<DoctorModel>> fetchTop({int limit = 25}) async {
    final all = await fetchAll();
    return pickTopDoctors(all, limit: limit);
  }

  /// Same algorithm as mobile/services/doctors.ts getTopDoctors.
  static List<DoctorModel> pickTopDoctors(List<DoctorModel> all, {int limit = 25}) {
    if (all.isEmpty) return [];

    var available = all.where((d) => d.available).toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    // If availability parsing filtered everyone out, still show doctors from the list.
    if (available.isEmpty) available = List<DoctorModel>.from(all);

    final picked = <DoctorModel>[];
    final seenSpec = <String>{};

    for (final d in available) {
      final key = d.specialization.toLowerCase().trim().isEmpty
          ? 'general'
          : d.specialization.toLowerCase().trim();
      if (seenSpec.contains(key)) continue;
      seenSpec.add(key);
      picked.add(d);
      if (picked.length >= limit) break;
    }

    if (picked.length < limit) {
      for (final d in available) {
        if (picked.any((p) => p.id == d.id)) continue;
        picked.add(d);
        if (picked.length >= limit) break;
      }
    }

    return picked;
  }
}
