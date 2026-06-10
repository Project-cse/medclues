import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// One native OS permission step (Android / iOS system dialog).
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

class AppPermissionsService {
  AppPermissionsService._();

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Order matters — each step triggers the **real** system dialog (one at a time).
  static List<PermissionStep> onboardingSteps() {
    if (!isMobile) return const [];

    return [
      const PermissionStep(
        id: 'notifications',
        title: 'Notifications',
        permission: Permission.notification,
        requestFcm: true,
      ),
      const PermissionStep(
        id: 'location',
        title: 'Location',
        permission: Permission.locationWhenInUse,
      ),
      if (Platform.isAndroid) ...[
        const PermissionStep(
          id: 'photos',
          title: 'Photos & files',
          permission: Permission.photos,
        ),
      ],
      const PermissionStep(
        id: 'camera',
        title: 'Camera',
        permission: Permission.camera,
      ),
      const PermissionStep(
        id: 'microphone',
        title: 'Microphone',
        permission: Permission.microphone,
      ),
      if (Platform.isAndroid)
        const PermissionStep(
          id: 'phone',
          title: 'Phone',
          permission: Permission.phone,
        ),
    ];
  }

  /// Requests permissions **sequentially** so Android/iOS shows native dialogs
  /// (Allow / Deny / While using the app — like Blinkit, TikTok, etc.).
  static Future<Map<String, PermissionStatus>> requestOnboardingSequentially({
    void Function(PermissionStep step)? onStepStarted,
  }) async {
    final results = <String, PermissionStatus>{};
    if (!isMobile) return results;

    for (final step in onboardingSteps()) {
      onStepStarted?.call(step);

      if (step.permission != null) {
        final perm = step.permission!;
        var status = await perm.status;
        if (!status.isGranted && !status.isLimited) {
          status = await perm.request();
        }
        results[step.id] = status;
      }

      if (step.requestFcm) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      }

      // Brief pause so the previous system sheet can dismiss before the next one.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return results;
  }

  static Future<bool> notificationsGranted() async {
    if (!isMobile) return false;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
