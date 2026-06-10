import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';

/// Parses API slot date (DD_MM_YYYY) + time label into local DateTime range.
class CalendarHelper {
  CalendarHelper._();

  static ({DateTime start, DateTime end})? parseSlotRange(String slotDate, String slotTime) {
    final dateParts = slotDate.replaceAll('-', '_').split('_');
    if (dateParts.length != 3) return null;
    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    if (day == null || month == null || year == null) return null;

    final rangeParts = slotTime.split(RegExp(r'\s*-\s*'));
    final startTime = _parseTimeLabel(rangeParts.first.trim(), year, month, day);
    if (startTime == null) return null;

    DateTime endTime;
    if (rangeParts.length > 1) {
      endTime = _parseTimeLabel(rangeParts[1].trim(), year, month, day) ??
          startTime.add(const Duration(hours: 1));
    } else {
      endTime = startTime.add(const Duration(hours: 1));
    }

    if (endTime.isBefore(startTime)) {
      endTime = startTime.add(const Duration(hours: 1));
    }
    return (start: startTime, end: endTime);
  }

  static DateTime? _parseTimeLabel(String label, int y, int m, int d) {
    try {
      final parsed = DateFormat('h:mm a').parse(label);
      return DateTime(y, m, d, parsed.hour, parsed.minute);
    } catch (_) {
      try {
        final parts = label.split(':');
        if (parts.length >= 2) {
          return DateTime(y, m, d, int.parse(parts[0]), int.parse(parts[1]));
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> addAppointmentToCalendar(AppointmentModel appointment) async {
    final range = parseSlotRange(appointment.slotDate, appointment.slotTime);
    if (range == null) return false;

    final location = [
      if (appointment.hospitalName != null && appointment.hospitalName!.isNotEmpty)
        appointment.hospitalName!,
      if (appointment.location != null && appointment.location!.isNotEmpty)
        appointment.location!,
    ].join(', ');

    final event = Event(
      title: 'Doctor appointment — ${appointment.doctorName}',
      description:
          '${appointment.specialization.isNotEmpty ? '${appointment.specialization}\n' : ''}'
          'MEDCLUES appointment${appointment.bookingId != null ? '\nBooking: ${appointment.bookingId}' : ''}',
      location: location.isEmpty ? null : location,
      startDate: range.start,
      endDate: range.end,
      iosParams: const IOSParams(reminder: Duration(hours: 1)),
      androidParams: const AndroidParams(emailInvites: []),
    );

    return Add2Calendar.addEvent2Cal(event);
  }
}
