class SlotModel {
  final String time;
  final String displayTime;
  final bool available;
  final int? slotId;
  final String? slotType;
  final int? availableCount;
  final int? totalCount;

  const SlotModel({
    required this.time,
    required this.displayTime,
    this.available = true,
    this.slotId,
    this.slotType,
    this.availableCount,
    this.totalCount,
  });
}

class DaySlotsModel {
  final String date;
  final String displayDate;
  final List<SlotModel> slots;

  const DaySlotsModel({
    required this.date,
    required this.displayDate,
    required this.slots,
  });
}

/// Infer OPD block type when the API omits `slot_type` (older backends).
String? inferOpdSlotType(String display, String? slotType) {
  if (slotType == 'morning_opd' || slotType == 'evening_opd') return slotType;
  final t = display.toLowerCase();
  if (t.contains('6:00') || t.contains('evening') || t.contains('9:00 pm')) {
    return 'evening_opd';
  }
  if (t.contains('10:00') || t.contains('morning') || t.contains('1:00 pm')) {
    return 'morning_opd';
  }
  return slotType;
}

/// OPD block end times (local): morning closes 1 PM, evening closes 9 PM.
const int _morningOpdEndMinutes = 13 * 60; // 1:00 PM
const int _eveningOpdEndMinutes = 21 * 60; // 9:00 PM

/// Parse a schedule day key (`DD_MM_YYYY`, `DD-MM-YYYY`, or ISO `YYYY-MM-DD`) to a date.
DateTime? parseSlotDateKey(String key) {
  final trimmed = key.trim();
  if (trimmed.isEmpty) return null;
  // ISO first (contains '-' with 4-digit leading year).
  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return DateTime(iso.year, iso.month, iso.day);
  final parts = trimmed.replaceAll('-', '_').split('_');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

bool _isTodayLocal(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

/// True when [slotDay] is today and the OPD block's end time has already passed.
bool opdBlockHasPassed(String? slotType, DateTime? slotDay) {
  if (slotDay == null || !_isTodayLocal(slotDay)) return false;
  final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
  switch (slotType) {
    case 'morning_opd':
      return nowMinutes >= _morningOpdEndMinutes;
    case 'evening_opd':
      return nowMinutes >= _eveningOpdEndMinutes;
    default:
      return false;
  }
}

/// True when an online slot's start time on [slotDay] (today) has already passed.
/// [display] examples: "2:00 PM - 2:15 PM", "02:00 PM".
bool onlineSlotHasPassed(String display, DateTime? slotDay) {
  if (slotDay == null || !_isTodayLocal(slotDay)) return false;
  final start = _parseStartMinutes(display);
  if (start == null) return false;
  final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
  return nowMinutes >= start;
}

int? _parseStartMinutes(String display) {
  final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(display);
  if (match == null) return null;
  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) return null;
  final ampm = match.group(3)?.toLowerCase();
  if (ampm == 'pm' && hour != 12) hour += 12;
  if (ampm == 'am' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

/// Morning OPD (10–1) before evening OPD (6–9).
int compareOpdSlotOrder(SlotModel a, SlotModel b) {
  int rank(String? type) {
    switch (type) {
      case 'morning_opd':
        return 0;
      case 'evening_opd':
        return 1;
      default:
        return 2;
    }
  }

  final order = rank(a.slotType).compareTo(rank(b.slotType));
  if (order != 0) return order;
  return a.displayTime.compareTo(b.displayTime);
}
