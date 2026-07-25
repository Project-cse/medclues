import '../models/blood_bank_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class BloodBankService {
  BloodBankService(this._api);

  final ApiService _api;

  Future<List<BloodBankModel>> fetchAll({String? search}) async {
    final res = await _api.get<Map<String, dynamic>>('/api/blood-bank/list');
    final data = res.data ?? {};
    assertSuccess(data);
    var list = unwrapList(data, ['bloodBanks', 'blood_banks']).map(BloodBankModel.fromJson).toList();
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list.where((b) => b.name.toLowerCase().contains(q) || b.address.toLowerCase().contains(q)).toList();
    }
    return list;
  }
}
