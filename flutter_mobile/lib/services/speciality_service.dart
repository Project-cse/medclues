import '../config/api_config.dart';
import '../models/speciality_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class SpecialityService {
  SpecialityService(this._api);

  final ApiService _api;

  Future<List<SpecialityModel>> fetchAll() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.specialtiesPublic);
    final data = res.data ?? {};
    assertSuccess(data);
    return unwrapList(data, ['data', 'specialties', 'specialities'])
        .map(SpecialityModel.fromJson)
        .toList();
  }
}
