import '../config/api_config.dart';

/// Resolves relative image paths from FastAPI (same as RN AvatarImage URLs).
String? resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
  if (u.startsWith('/')) return '$base$u';
  return '$base/$u';
}
