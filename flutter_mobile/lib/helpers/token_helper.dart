import 'dart:convert';

class TokenHelper {
  TokenHelper._();

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool isExpired(String token) {
    final payload = decodePayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp is! num) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().isAfter(expiry);
  }
}
