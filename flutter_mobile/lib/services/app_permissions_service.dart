import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contextual native OS permissions — request only when a feature is used.
class AppPermissionsService {
  AppPermissionsService._();

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<PermissionStatus> _requestIfNeeded(Permission permission) async {
    if (!isMobile) return PermissionStatus.granted;
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return status;
    return permission.request();
  }

  /// Location — emergency SOS, nearby hospitals.
  static Future<bool> ensureLocation() async {
    final status = await _requestIfNeeded(Permission.locationWhenInUse);
    return status.isGranted || status.isLimited;
  }

  /// Camera — video consult, profile photo (camera source).
  static Future<bool> ensureCamera() async {
    final status = await _requestIfNeeded(Permission.camera);
    return status.isGranted || status.isLimited;
  }

  /// Microphone — video consult.
  static Future<bool> ensureMicrophone() async {
    final status = await _requestIfNeeded(Permission.microphone);
    return status.isGranted || status.isLimited;
  }

  /// Photos / gallery — upload reports, prescriptions, profile image.
  static Future<bool> ensurePhotos() async {
    if (!isMobile) return true;
    if (Platform.isAndroid) {
      final photos = await _requestIfNeeded(Permission.photos);
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await _requestIfNeeded(Permission.storage);
      return storage.isGranted || storage.isLimited;
    }
    final status = await _requestIfNeeded(Permission.photos);
    return status.isGranted || status.isLimited;
  }

  /// Push notifications — after login / appointment updates.
  static Future<bool> ensureNotifications() async {
    if (!isMobile) return false;
    final status = await _requestIfNeeded(Permission.notification);
    if (status.isGranted || status.isLimited) return true;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Phone — emergency dialer.
  static Future<bool> ensurePhone() async {
    if (!isMobile || !Platform.isAndroid) return true;
    final status = await _requestIfNeeded(Permission.phone);
    return status.isGranted;
  }

  /// Video consult — camera + microphone together.
  static Future<bool> ensureVideoConsult() async {
    if (!isMobile) return true;
    final results = await [Permission.camera, Permission.microphone].request();
    return results.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Open system settings when user permanently denied a permission.
  static Future<void> openSettingsIfPermanentlyDenied(Permission permission) async {
    if (!isMobile) return;
    if (await permission.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  static Future<bool> notificationsGranted() async {
    if (!isMobile) return false;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Legacy screen support — router no longer forces this flow.
  static List<PermissionStep> onboardingSteps() {
    if (!isMobile) return const [];
    return const [
      PermissionStep(
        id: 'notifications',
        title: 'Notifications',
        permission: Permission.notification,
        requestFcm: true,
      ),
      PermissionStep(
        id: 'location',
        title: 'Location',
        permission: Permission.locationWhenInUse,
      ),
    ];
  }

  static Future<Map<String, PermissionStatus>> requestOnboardingSequentially({
    void Function(PermissionStep step)? onStepStarted,
  }) async {
    final results = <String, PermissionStatus>{};
    for (final step in onboardingSteps()) {
      onStepStarted?.call(step);
      if (step.id == 'notifications') {
        await ensureNotifications();
        results[step.id] = await Permission.notification.status;
      } else if (step.id == 'location') {
        await ensureLocation();
        results[step.id] = await Permission.locationWhenInUse.status;
      }
    }
    return results;
  }
}

/// Legacy screen support — router no longer forces this flow.
class PermissionStep {
  const PermissionStep({
    required this.id,
    required this.title,
    this.permission,
    this.requestFcm = false,
  });

  final String id;
  final String title;
  final Permission? permission;
  final bool requestFcm;
}
