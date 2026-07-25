import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../utils/json_parser.dart';
import 'api_service.dart';

class HealthProtectionService {
  HealthProtectionService(this._api);
  final ApiService _api;

  Exception _fail(dynamic data, [String fallback = 'Request failed']) {
    if (data is Map) return Exception('${data['message'] ?? fallback}');
    return Exception(fallback);
  }

  Future<Map<String, dynamic>> hub() async {
    final res = await _api.get('/api/health-protection/hub');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data, 'Could not load hub');
  }

  Future<Map<String, dynamic>> recomputeScore() async {
    final res = await _api.post('/api/health-protection/score/recompute');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final res = await _api.get('/api/health-protection/plans');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> recommend(Map<String, dynamic> profile) async {
    final res =
        await _api.post('/api/health-protection/recommend', data: profile);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> compare(List<int> planIds) async {
    final res = await _api
        .post('/api/health-protection/compare', data: {'planIds': planIds});
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<List<Map<String, dynamic>>> eligibility(
      Map<String, dynamic> body) async {
    final res =
        await _api.post('/api/health-protection/eligibility', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return unwrapList((data['data'] as Map)['results']);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>?> emergencyCard() async {
    final res = await _api.get('/api/health-protection/emergency-card');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      if (data['data'] == null) return null;
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> saveEmergencyCard(
      Map<String, dynamic> body) async {
    final res =
        await _api.put('/api/health-protection/emergency-card', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Uint8List> emergencyCardPdf() async {
    final res = await _api.dio.get<List<int>>(
      '/api/health-protection/emergency-card/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? []);
  }

  Future<Map<String, dynamic>> analyzePolicy({
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _api.dio.post(
      '/api/health-protection/policy/analyze',
      data: form,
    );
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<List<Map<String, dynamic>>> claims() async {
    final res = await _api.get('/api/health-protection/claims');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> createClaim(Map<String, dynamic> body) async {
    final res = await _api.post('/api/health-protection/claims', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> getClaim(int id) async {
    final res = await _api.get('/api/health-protection/claims/$id');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> uploadClaimDoc({
    required int claimId,
    required String docType,
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'doc_type': docType,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _api.dio.post(
      '/api/health-protection/claims/$claimId/documents',
      data: form,
    );
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> submitClaim(int id) async {
    final res = await _api.post('/api/health-protection/claims/$id/submit');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<List<Map<String, dynamic>>> cashless({
    double? lat,
    double? lng,
    String? insurer,
  }) async {
    final res = await _api.get('/api/health-protection/cashless-hospitals',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (insurer != null) 'insurer': insurer,
        });
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']);
    }
    throw _fail(data);
  }

  Future<List<Map<String, dynamic>>> family() async {
    final res = await _api.get('/api/health-protection/family');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> addFamily(Map<String, dynamic> body) async {
    final res = await _api.post('/api/health-protection/family', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<void> deleteFamily(int id) async {
    await _api.delete('/api/health-protection/family/$id');
  }

  Future<List<Map<String, dynamic>>> expenses() async {
    final res = await _api.get('/api/health-protection/expenses');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> body) async {
    final res = await _api.post('/api/health-protection/expenses', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> expenseCharts() async {
    final res = await _api.get('/api/health-protection/expenses/charts');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> computeRisk(Map<String, dynamic> body) async {
    final res =
        await _api.post('/api/health-protection/risk-score', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<String> chat(String message) async {
    final res = await _api
        .post('/api/health-protection/chat', data: {'message': message});
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return '${(data['data'] as Map)['reply'] ?? ''}';
    }
    throw _fail(data);
  }

  Future<List<Map<String, dynamic>>> chatHistory() async {
    final res = await _api.get('/api/health-protection/chat/history');
    final data = res.data;
    if (data is Map && data['success'] == true) {
      return unwrapList(data['results']);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> analytics() async {
    final res = await _api.get('/api/health-protection/analytics/summary');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> renewalRemind() async {
    final res = await _api.post('/api/health-protection/renewal/remind');
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }

  Future<Map<String, dynamic>> createPolicy(Map<String, dynamic> body) async {
    final res = await _api.post('/api/health-protection/policies', data: body);
    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw _fail(data);
  }
}
