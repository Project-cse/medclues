List<Map<String, dynamic>> unwrapList(
  dynamic data, [
  List<String> keys = const ['data', 'doctors', 'appointments', 'specialties', 'specialities'],
]) {
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final v = data[key];
      if (v is List) {
        return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
  }
  return [];
}

void assertSuccess(Map<String, dynamic> data, [String? fallback]) {
  if (data['success'] == false) {
    throw Exception(data['message']?.toString() ?? fallback ?? 'Request failed');
  }
}
