extension ListExtensions<T> on List<T> {
  List<T> safeSublist(int start, [int? end]) {
    if (isEmpty) return [];
    final s = start.clamp(0, length);
    final e = (end ?? length).clamp(0, length);
    if (s >= e) return [];
    return sublist(s, e);
  }
}

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
