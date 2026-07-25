import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../features/emergency/models/emergency_contact_model.dart';
import '../features/emergency/services/emergency_location_service.dart';
import '../features/emergency/services/emergency_notification_service.dart';

/// Shares live GPS with emergency contacts every few minutes for 30 minutes.
class LiveLocationShareService {
  LiveLocationShareService({
    EmergencyLocationService? locationService,
    EmergencyNotificationService? notificationService,
  })  : _location = locationService ?? EmergencyLocationService(),
        _notify = notificationService ?? EmergencyNotificationService();

  final EmergencyLocationService _location;
  final EmergencyNotificationService _notify;

  static const shareDuration = Duration(minutes: 30);
  static const updateInterval = Duration(minutes: 3);

  Timer? _timer;
  DateTime? _endsAt;
  int _updatesSent = 0;

  bool get isActive => _timer != null;

  Duration? get remaining {
    final end = _endsAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<bool> start({
    required List<EmergencyContactModel> contacts,
    String? patientName,
  }) async {
    if (contacts.isEmpty) return false;
    if (isActive) return true;

    final ok = await _location.ensurePermission();
    if (!ok) return false;

    _endsAt = DateTime.now().add(shareDuration);
    _updatesSent = 0;

    await _sendUpdate(contacts, patientName, isFirst: true);

    _timer = Timer.periodic(updateInterval, (_) async {
      if (DateTime.now().isAfter(_endsAt!)) {
        stop();
        return;
      }
      await _sendUpdate(contacts, patientName);
    });

    return true;
  }

  Future<void> _sendUpdate(
    List<EmergencyContactModel> contacts,
    String? patientName, {
    bool isFirst = false,
  }) async {
    final pos = await _tryPosition();
    if (pos == null) return;

    final link = EmergencyLocationService.mapsLink(pos.latitude, pos.longitude);
    final minsLeft = _endsAt?.difference(DateTime.now()).inMinutes ?? 30;
    final name = patientName?.trim().isNotEmpty == true ? patientName!.trim() : 'Patient';

    final msg = isFirst
        ? '📍 *MEDCLUES Live Location*\n$name is sharing live location for 30 minutes.\n\nOpen map:\n$link\n\nUpdates every 3 min.'
        : '📍 *Location update* ($name)\n$link\n\nSharing ends in ~${minsLeft.clamp(0, 30)} min.';

    for (final c in contacts.take(2)) {
      await _notify.openWhatsAppMessage(phone: c.phone, message: msg);
    }
    _updatesSent++;
  }

  Future<Position?> _tryPosition() async {
    try {
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
  }
}
