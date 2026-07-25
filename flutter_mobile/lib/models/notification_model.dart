enum NotificationType { appointment, reminder, system }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool read;
  final String? appointmentId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = NotificationType.system,
    this.read = false,
    this.appointmentId,
  });
}
