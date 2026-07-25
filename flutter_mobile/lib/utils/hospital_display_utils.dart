/// Display helpers for hospital listing cards.
List<String> parseHospitalSpecializationChips(String? specialization, {int maxVisible = 3}) {
  if (specialization == null || specialization.trim().isEmpty) return [];
  final parts = specialization
      .split(RegExp(r'[,/&+]|\band\b', caseSensitive: false))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return parts;
}

String formatHospitalTravelTime(double distanceKm) {
  // Urban average ~28 km/h for ETA display.
  final minutes = (distanceKm / 28 * 60).round().clamp(1, 180);
  return '$minutes mins';
}
