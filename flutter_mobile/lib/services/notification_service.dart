import '../config/api_config.dart';
import '../models/appointment_model.dart';
import '../models/notification_model.dart';
import '../utils/date_formatter.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';
import 'appointment_service.dart';

/// Notifications now come from the persistent backend feed (`/api/user/notifications`),
/// which records every push (booking, reminder, cancellation, prescription, etc.).
/// If the backend feed is empty/unreachable we fall back to deriving a feed from
/// the user's appointments so the page is never blank.
class NotificationService {
  NotificationService(this._api, this._appointments);

  final ApiService _api;
  final AppointmentService _appointments;

  Future<List<NotificationModel>> fetchAll() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiConfig.userNotifications);
      final data = res.data ?? {};
      final list = unwrapList(data, ['notifications']).map(_fromJson).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // fall through to appointment-derived feed
    }
    return _deriveFromAppointments();
  }

  Future<void> markRead(String id) async {
    try {
      await _api.post(ApiConfig.userNotificationsRead, data: {'id': id});
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.post(ApiConfig.userNotificationsReadAll);
    } catch (_) {}
  }

  NotificationModel _fromJson(Map<String, dynamic> j) {
    final appt = j['appointmentId'];
    final apptStr = (appt == null || '$appt'.isEmpty) ? null : '$appt';
    return NotificationModel(
      id: '${j['id']}',
      title: '${j['title'] ?? ''}',
      message: '${j['message'] ?? j['body'] ?? ''}',
      timestamp: DateTime.tryParse('${j['createdAt'] ?? ''}')?.toLocal() ?? DateTime.now(),
      type: _typeFrom('${j['type'] ?? 'system'}'),
      read: j['read'] == true,
      appointmentId: apptStr,
    );
  }

  NotificationType _typeFrom(String t) {
    final s = t.toLowerCase();
    if (s.contains('reminder')) return NotificationType.reminder;
    if (s.contains('appointment')) return NotificationType.appointment;
    return NotificationType.system;
  }

  // ---- Fallback: derive a feed from appointments ----------------------------

  Future<List<NotificationModel>> _deriveFromAppointments() async {
    try {
      final all = await _appointments.fetchAppointments();
      final items = all.map(_fromAppointment).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (_) {
      return [];
    }
  }

  static String _doctorLabel(String name) {
    final n = name.trim();
    final lower = n.toLowerCase();
    if (lower.startsWith('dr.') || lower.startsWith('dr ')) return n;
    return 'Dr. $n';
  }

  DateTime _appointmentDateTime(AppointmentModel a) {
    try {
      final dp = a.slotDate.split('_');
      if (dp.length != 3) return DateTime.now();
      final d = int.parse(dp[0]);
      final m = int.parse(dp[1]);
      final y = int.parse(dp[2]);
      var hh = 0;
      var mm = 0;
      final tp = a.slotTime.split(':');
      if (tp.length >= 2) {
        hh = int.tryParse(tp[0]) ?? 0;
        mm = int.tryParse(tp[1]) ?? 0;
      }
      return DateTime(y, m, d, hh, mm);
    } catch (_) {
      return DateTime.now();
    }
  }

  NotificationModel _fromAppointment(AppointmentModel a) {
    final when = _appointmentDateTime(a);
    final dateLabel = DateFormatter.formatSlotDate(a.slotDate);
    final timeLabel = DateFormatter.displayTime(a.slotTime);
    final doctor = _doctorLabel(a.doctorName);
    final who = a.patientLabel.trim().isNotEmpty && a.patientLabel != 'You'
        ? '${a.patientLabel}: '
        : '';

    if (a.cancelled || a.status == 'cancelled') {
      return NotificationModel(
        id: 'cancel_${a.id}',
        title: 'Appointment cancelled',
        message: '${who}Appointment with $doctor on $dateLabel at $timeLabel was cancelled.',
        timestamp: when,
        type: NotificationType.system,
        appointmentId: a.id,
      );
    }

    if (a.isCompleted || a.status == 'completed') {
      return NotificationModel(
        id: 'done_${a.id}',
        title: 'Consultation completed',
        message: '${who}Visit with $doctor on $dateLabel is complete. Tap to view prescription & records.',
        timestamp: when,
        type: NotificationType.system,
        appointmentId: a.id,
      );
    }

    return NotificationModel(
      id: 'appt_${a.id}',
      title: 'Upcoming appointment',
      message: '$who$doctor · $dateLabel at $timeLabel'
          '${a.hospitalName != null && a.hospitalName!.isNotEmpty ? ' · ${a.hospitalName}' : ''}',
      timestamp: when,
      type: NotificationType.appointment,
      appointmentId: a.id,
    );
  }
}
