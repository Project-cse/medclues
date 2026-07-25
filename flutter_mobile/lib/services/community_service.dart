import '../utils/json_parser.dart';
import 'api_service.dart';

class CommunityService {
  CommunityService(this._api);

  final ApiService _api;

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is Map && data['success'] == true) {
      return unwrapList(data['data']);
    }
    throw Exception(
      data is Map ? (data['message'] ?? 'Request failed') : 'Request failed',
    );
  }

  Map<String, dynamic> _map(dynamic data, [String fallback = 'Failed']) {
    if (data is Map && data['success'] == true) {
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return Map<String, dynamic>.from(data);
    }
    throw Exception(data is Map ? (data['message'] ?? fallback) : fallback);
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final res = await _api.get('/api/user/community/categories');
    return _list(res.data);
  }

  Future<List<Map<String, dynamic>>> feed({
    String sort = 'recent',
    String? specialty,
  }) async {
    final res = await _api.get('/api/user/community/feed', queryParameters: {
      'sort': sort,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
    });
    return _list(res.data);
  }

  Future<Map<String, dynamic>> search(String q) async {
    final res = await _api.get('/api/user/community/search', queryParameters: {
      'q': q,
    });
    if (res.data is Map && res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw Exception('Search failed');
  }

  Future<Map<String, dynamic>> ask({
    required String title,
    required String body,
    String specialty = 'general',
    bool force = false,
  }) async {
    final res = await _api.post('/api/user/community/questions', data: {
      'title': title,
      'body': body,
      'specialty': specialty,
      'force': force,
      'stillAsk': force,
    });
    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw Exception('Ask failed');
  }

  Future<Map<String, dynamic>> detail(int id) async {
    final res = await _api.get('/api/user/community/questions/$id');
    return _map(res.data, 'Not found');
  }

  Future<List<Map<String, dynamic>>> myQuestions() async {
    final res = await _api.get('/api/user/community/my-questions');
    return _list(res.data);
  }

  Future<List<Map<String, dynamic>>> bookmarks() async {
    final res = await _api.get('/api/user/community/bookmarks');
    return _list(res.data);
  }

  Future<void> bookmark(int id) async {
    await _api.post('/api/user/community/questions/$id/bookmark');
  }

  Future<void> unbookmark(int id) async {
    await _api.delete('/api/user/community/questions/$id/bookmark');
  }

  Future<void> followUp(int id, String body) async {
    final res = await _api.post(
      '/api/user/community/questions/$id/follow-up',
      data: {'body': body},
    );
    if (res.data is Map && res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Follow-up failed');
    }
  }

  Future<void> report({
    required String targetType,
    required int targetId,
    required String reason,
  }) async {
    await _api.post('/api/user/community/report', data: {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> archive({String? specialty, String? q}) async {
    final res = await _api.get('/api/user/community/archive', queryParameters: {
      if (specialty != null) 'specialty': specialty,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    if (res.data is Map && res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw Exception('Archive failed');
  }

  Future<void> voteHelpful(int answerId, {int value = 1}) async {
    final res = await _api.post('/api/user/community/answers/$answerId/vote', data: {
      'value': value,
    });
    if (res.data is Map && res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Vote failed');
    }
  }

  Future<Map<String, dynamic>> plusStatus() async {
    final res = await _api.get('/api/user/community/plus');
    return _map(res.data, 'Plus status failed');
  }

  Future<Map<String, dynamic>> activatePlus() async {
    final res = await _api.post('/api/user/community/plus/activate');
    return _map(res.data, 'Activate failed');
  }
}