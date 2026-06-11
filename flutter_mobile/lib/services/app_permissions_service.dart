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

  /// Throws if camera or microphone is not granted (blocks native Agora crash).
  static Future<({bool camera, bool microphone})> requireVideoConsult() async {
    if (!isMobile) return (camera: true, microphone: true);

    var cam = await Permission.camera.status;
    var mic = await Permission.microphone.status;
    if (!cam.isGranted && !cam.isLimited) cam = await Permission.camera.request();
    if (!mic.isGranted && !mic.isLimited) mic = await Permission.microphone.request();

    final cameraOk = cam.isGranted || cam.isLimited;
    final micOk = mic.isGranted || mic.isLimited;

    if (!cameraOk || !micOk) {
      if (cam.isPermanentlyDenied) {
        await openAppSettings();
      } else if (mic.isPermanentlyDenied) {
        await openAppSettings();
      }
      throw VideoConsultPermissionException(
        cameraOk: cameraOk,
        microphoneOk: micOk,
      );
    }
    return (camera: cameraOk, microphone: micOk);
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
class VideoConsultPermissionException implements Exception {
  VideoConsultPermissionException({required this.cameraOk, required this.microphoneOk});

  final bool cameraOk;
  final bool microphoneOk;

  @override
  String toString() {
    if (!cameraOk && !microphoneOk) {
      return 'Camera and microphone permissions are required for video consultation.';
    }
    if (!cameraOk) return 'Camera permission is required for video consultation.';
    return 'Microphone permission is required for video consultation.';
  }
}

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
