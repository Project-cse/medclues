// Enterprise AI Medical Assistant client (AI_ASSISTANT_ENABLED on server).
// Calls /api/ai/assistant/* — never diagnoses; write tools need confirm.
import 'package:dio/dio.dart';

class AiAssistantService {
  AiAssistantService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> status() async {
    final res = await _dio.get('/api/ai/assistant/status');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> chat({
    required String message,
    String sessionId = 'default',
    String? tool,
    Map<String, dynamic>? toolArgs,
    bool confirm = false,
  }) async {
    final res = await _dio.post(
      '/api/ai/assistant/chat',
      data: {
        'message': message,
        'sessionId': sessionId,
        if (tool != null) 'tool': tool,
        if (toolArgs != null) 'toolArgs': toolArgs,
        'confirm': confirm,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> confirm({
    required String tool,
    Map<String, dynamic>? toolArgs,
    String sessionId = 'default',
    String message = '',
  }) async {
    final res = await _dio.post(
      '/api/ai/assistant/confirm',
      data: {
        'tool': tool,
        'toolArgs': toolArgs ?? {},
        'sessionId': sessionId,
        'message': message,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> feedback({
    required int rating,
    String sessionId = 'default',
    String? intent,
    String? tool,
    String? comment,
    String? query,
  }) async {
    final res = await _dio.post(
      '/api/ai/assistant/feedback',
      data: {
        'rating': rating,
        'sessionId': sessionId,
        if (intent != null) 'intent': intent,
        if (tool != null) 'tool': tool,
        if (comment != null) 'comment': comment,
        if (query != null) 'query': query,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
