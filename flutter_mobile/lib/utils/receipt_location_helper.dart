/// Parses doctor address fields for receipt display.
/// address line1 = floor / wing / block; line2 = room no when it looks like one.
class ReceiptLocationInfo {
  const ReceiptLocationInfo({this.roomNo, this.floorOrLocation});

  final String? roomNo;
  final String? floorOrLocation;

  bool get hasRoom => roomNo != null && roomNo!.isNotEmpty;
  bool get hasFloor => floorOrLocation != null && floorOrLocation!.isNotEmpty;
}

ReceiptLocationInfo parseReceiptLocation({
  String? addressLine1,
  String? addressLine2,
  String? hospitalName,
}) {
  final floor = _clean(addressLine1);
  final room = _roomFromLine2(addressLine2, hospitalName);
  return ReceiptLocationInfo(
    roomNo: room,
    floorOrLocation: floor,
  );
}

String? _clean(String? value) {
  final t = value?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

bool _looksLikeRoomNo(String value, String? hospitalName) {
  final t = value.trim();
  if (t.isEmpty) return false;

  final lower = t.toLowerCase();
  final hospital = hospitalName?.trim().toLowerCase();
  if (hospital != null && hospital.isNotEmpty) {
    if (lower == hospital) return false;
    if (lower.contains(hospital)) return false;
  }

  // Seed script stored hospital name in line2 — exclude hospital-like text.
  if (lower.contains('hospital') || lower.contains('multispecial')) return false;
  if (t.contains(',')) return false;

  if (RegExp(r'^(room\s*#?\s*)?\d{1,4}[a-z]?$', caseSensitive: false).hasMatch(t)) {
    return true;
  }
  if (RegExp(r'^#?\d{1,4}[a-z]?$', caseSensitive: false).hasMatch(t)) return true;

  return false;
}

String? _roomFromLine2(String? line2, String? hospitalName) {
  final t = _clean(line2);
  if (t == null) return null;
  if (!_looksLikeRoomNo(t, hospitalName)) return null;
  final normalized = RegExp(r'^room\s*', caseSensitive: false).hasMatch(t)
      ? t
      : 'Room $t';
  return normalized;
}
