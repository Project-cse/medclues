import 'package:flutter/foundation.dart';

enum NotificationChannel { push, sms, inApp, email }

class NotificationPayload {
  const NotificationPayload({
    required this.title,
    required this.body,
    this.phone,
    this.email,
    this.orderId,
  });

  final String title;
  final String body;
  final String? phone;
  final String? email;
  final String? orderId;
}

/// Cascading Multi-Channel Notification Dispatcher
/// Tries Push Notification (FCM) first. If FCM drops/fails 3x, escalates to SMS, then In-App/Email.
/// Channels are wired only when real providers exist — stubs must not report success.
class NotificationCascadeService {
  Future<bool> sendNotification(NotificationPayload payload) async {
    // 1. Try FCM Push Notification (Primary Channel)
    bool pushSuccess = await _tryPushNotification(payload);
    if (pushSuccess) {
      if (kDebugMode) print('Notification delivered via FCM Push');
      return true;
    }

    // 2. Escalation Channel 1: SMS Delivery
    if (kDebugMode) print('Push Notification unavailable. Escalating to SMS...');
    bool smsSuccess = await _trySmsNotification(payload);
    if (smsSuccess) {
      if (kDebugMode) print('Notification delivered via SMS');
      return true;
    }

    // 3. Escalation Channel 2: In-App Alert & Email Sync (Fallback Channel)
    if (kDebugMode) print('SMS unavailable. Escalating to In-App Alert & Email Sync...');
    final emailSuccess = await _tryEmailNotification(payload);
    return emailSuccess;
  }

  Future<bool> _tryPushNotification(NotificationPayload payload) async {
    try {
      // FCM not wired in this client path — do not pretend delivery succeeded.
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _trySmsNotification(NotificationPayload payload) async {
    try {
      if (payload.phone == null || payload.phone!.isEmpty) return false;
      // SMS gateway not wired — do not pretend delivery succeeded.
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryEmailNotification(NotificationPayload payload) async {
    try {
      if (payload.email == null || payload.email!.isEmpty) return false;
      // Email send not wired — do not pretend delivery succeeded.
      return false;
    } catch (_) {
      return false;
    }
  }
}
