import '../models/medicine_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class MedicineService {
  MedicineService(this._api);

  final ApiService _api;

  Exception _fail(dynamic data, [String fallback = 'Request failed']) {
    if (data is Map) {
      return Exception('${data['message'] ?? fallback}');
    }
    return Exception(fallback);
  }

  Future<List<MedicineCard>> search(
    String q, {
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _api.get(
      '/api/medicine/search',
      queryParameters: {'q': q, 'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results'])
          .map((e) => MedicineCard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw _fail(data, 'Search failed');
  }

  Future<List<String>> autocomplete(String q, {int limit = 10}) async {
    final res = await _api.get(
      '/api/medicine/autocomplete',
      queryParameters: {'q': q, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      final list = data['suggestions'];
      if (list is List) {
        return list.map((e) => '$e').where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }
    throw _fail(data, 'Autocomplete failed');
  }

  Future<MedicineDetails> details(String medicineName) async {
    final encoded = Uri.encodeComponent(medicineName);
    final res = await _api.get('/api/medicine/details/$encoded');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return MedicineDetails.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }
    throw _fail(data, 'Medicine not found');
  }

  Future<List<MedicineCard>> byManufacturer(
    String manufacturer, {
    int page = 1,
    int limit = 10,
  }) async {
    final encoded = Uri.encodeComponent(manufacturer);
    final res = await _api.get(
      '/api/medicine/manufacturer/$encoded',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results'])
          .map((e) => MedicineCard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw _fail(data);
  }

  Future<List<MedicineCard>> byIngredient(
    String ingredient, {
    int page = 1,
    int limit = 10,
  }) async {
    final encoded = Uri.encodeComponent(ingredient);
    final res = await _api.get(
      '/api/medicine/ingredient/$encoded',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results'])
          .map((e) => MedicineCard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw _fail(data);
  }

  Future<List<String>> recentSearches({int limit = 10}) async {
    final res = await _api.get(
      '/api/medicine/recent',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results'])
          .map((e) => '${e['query'] ?? ''}')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    throw _fail(data);
  }

  Future<List<String>> popular({int limit = 10}) async {
    final res = await _api.get(
      '/api/medicine/popular',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results'])
          .map((e) => '${e['query'] ?? ''}')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    throw _fail(data);
  }

  Future<List<String>> trending({int limit = 10}) async {
    final res = await _api.get(
      '/api/medicine/trending',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results'])
          .map((e) => '${e['query'] ?? ''}')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    throw _fail(data);
  }

  Future<void> addFavorite(MedicineCard card) async {
    final res = await _api.post('/api/medicine/favorites', data: {
      'medicineKey': card.medicineKey,
      'brandName': card.brandName,
      'genericName': card.genericName,
      'manufacturer': card.manufacturer,
      'dosageForm': card.dosageForm,
      'shortDescription': card.shortDescription,
    });
    final data = res.data;
    if (data is! Map || data['success'] != true) {
      throw _fail(data, 'Could not save favorite');
    }
  }

  Future<void> removeFavorite(String medicineKey) async {
    final encoded = Uri.encodeComponent(medicineKey);
    final res = await _api.delete('/api/medicine/favorites/$encoded');
    final data = res.data;
    if (data is! Map || data['success'] != true) {
      throw _fail(data, 'Could not remove favorite');
    }
  }

  Future<List<MedicineCard>> favorites() async {
    final res = await _api.get('/api/medicine/favorites');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return MedicineCard(
          medicineKey: '${m['medicineKey'] ?? ''}',
          medicineName: '${m['brandName'] ?? m['genericName'] ?? 'Medicine'}',
          brandName: m['brandName']?.toString(),
          genericName: m['genericName']?.toString(),
          manufacturer: m['manufacturer']?.toString(),
          dosageForm: m['dosageForm']?.toString(),
          shortDescription: m['shortDescription']?.toString(),
        );
      }).toList();
    }
    throw _fail(data);
  }
}
