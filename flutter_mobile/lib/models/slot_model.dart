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
