import '../config/api_config.dart';
import '../models/lab_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class LabService {
  LabService(this._api);

  final ApiService _api;

  Future<List<LabModel>> fetchAll({String? search}) async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.labList);
    final data = res.data ?? {};
    assertSuccess(data);
    var list = unwrapList(data, ['labs']).map(LabModel.fromJson).toList();
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list.where((l) => l.name.toLowerCase().contains(q) || l.address.toLowerCase().contains(q)).toList();
    }
    return list;
  }
}
