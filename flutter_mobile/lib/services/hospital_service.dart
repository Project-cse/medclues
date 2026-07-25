import '../config/api_config.dart';
import '../models/doctor_model.dart';
import '../models/hospital_detail_model.dart';
import '../models/hospital_model.dart';
import '../utils/json_parser.dart';
import '../utils/location_utils.dart';
import 'api_service.dart';

class HospitalService {
  HospitalService(this._api);

  final ApiService _api;

  Future<List<HospitalModel>> fetchAll({String? search}) async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.hospitalList);
    final data = res.data ?? {};
    assertSuccess(data);
    var list = unwrapList(data, ['hospitals', 'hospitalTieups', 'data'])
        .map(HospitalModel.fromJson)
        .toList();
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list
          .where((h) => h.name.toLowerCase().contains(q) || h.address.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<HospitalDetailModel> fetchDetails(String hospitalId) async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.hospitalDetails(hospitalId));
    final data = res.data ?? {};
    assertSuccess(data, 'Hospital not found');
    final raw = data['hospital'];
    if (raw is! Map) throw Exception('Hospital not found');
    final map = Map<String, dynamic>.from(raw);
    final doctorsRaw = map.remove('doctors');
    final hospital = HospitalModel.fromJson(map);
    final doctors = <DoctorModel>[];
    if (doctorsRaw is List) {
      for (final item in doctorsRaw) {
        if (item is Map) {
          doctors.add(DoctorModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return HospitalDetailModel(hospital: hospital, doctors: doctors);
  }

  /// Partnered hospitals within [radiusKm] of user, plus OSM discoveries (web parity).
  Future<List<HospitalModel>> fetchNearby({
    required double lat,
    required double lon,
    double radiusKm = 10,
    required List<HospitalModel> partneredHospitals,
  }) async {
    final nearbyPartnered = partneredHospitals
        .map((h) {
          if (h.latitude == null || h.longitude == null) return null;
          final dist = calculateDistanceKm(lat, lon, h.latitude!, h.longitude!);
          if (dist > radiusKm) return null;
          return h.copyWith(distanceKm: dist);
        })
        .whereType<HospitalModel>()
        .toList();

    List<HospitalModel> discoveries = [];
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiConfig.nearbyHospitals(lat, lon, radiusKm: radiusKm),
      );
      final data = res.data ?? {};
      if (data['success'] == true && data['hospitals'] is List) {
        for (final item in data['hospitals'] as List) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final hLat = (m['latitude'] as num?)?.toDouble();
          final hLon = (m['longitude'] as num?)?.toDouble();
          if (hLat == null || hLon == null) continue;
          discoveries.add(
            HospitalModel(
              id: 'osm_${hLat}_$hLon',
              name: '${m['name'] ?? 'Hospital'}',
              address: '${m['address'] ?? ''}',
              specialization: m['specialization']?.toString(),
              type: m['type']?.toString(),
              contact: m['phone']?.toString(),
              latitude: hLat,
              longitude: hLon,
              distanceKm: (m['distance'] as num?)?.toDouble() ??
                  calculateDistanceKm(lat, lon, hLat, hLon),
              isRealHospital: true,
            ),
          );
        }
      }
    } catch (_) {
      // OSM discovery optional — still show partnered nearby.
    }

    final combined = [...nearbyPartnered, ...discoveries]
      ..sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    return combined;
  }
}
