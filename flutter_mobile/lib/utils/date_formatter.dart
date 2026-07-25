import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _display = DateFormat('dd MMM yyyy');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  static String displayDate(DateTime date) => _display.format(date);
  static String displayTime(String slotTime) {
    try {
      final parts = slotTime.split(':');
      if (parts.length >= 2) {
        final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
        return _time.format(dt);
      }
    } catch (_) {}
    return slotTime;
  }

  static String apiDate(DateTime date) => _apiDate.format(date);

  static List<DateTime> next7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) => DateTime(today.year, today.month, today.day + i));
  }

  /// API slot dates use DD_MM_YYYY (matches mobile/utils/format.ts).
  static String slotDateFromDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '${day}_${month}_${d.year}';
  }

  static const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static List<({String label, int dayNum, String slotDate, String monthShort})> buildNext5Days() {
    return buildNext7Days().take(5).toList();
  }

  static List<({String label, int dayNum, String slotDate, String monthShort})> buildNext7Days() {
    final today = DateTime.now();
    final monthFmt = DateFormat('MMM');
    final out = <({String label, int dayNum, String slotDate, String monthShort})>[];
    for (var i = 0; i < 7; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      out.add((
        label: i == 0 ? 'Today' : _weekdayLabels[d.weekday % 7],
        dayNum: d.day,
        slotDate: slotDateFromDate(d),
        monthShort: monthFmt.format(d),
      ));
    }
    return out;
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// API slot dates use DD_MM_YYYY (e.g. 26_05_2026).
  static String formatSlotDate(String slotDate) {
    if (slotDate.isEmpty) return '';
    final parts = slotDate.split('_');
    if (parts.length != 3) return slotDate.replaceAll('_', '/');
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return slotDate.replaceAll('_', '/');
    try {
      return DateFormat('dd MMM yyyy').format(DateTime(y, m, d));
    } catch (_) {
      return slotDate.replaceAll('_', '/');
    }
  }
}
