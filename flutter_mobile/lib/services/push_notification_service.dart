import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import 'app_permissions_service.dart';
import '../routes/route_names.dart';
import 'api_service.dart';

const _channelId = 'medclues_appointments';
const _channelName = 'MEDCLUES Appointments';
const _videoChannelId = 'medclues_video_calls';
const _videoChannelName = 'MEDCLUES Video Calls';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('FCM background: ${message.notification?.title}');
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  ApiService? _api;
  GlobalKey<NavigatorState>? _navKey;
  bool _initialized = false;
  String? _cachedToken;

  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void bind({required ApiService api, required GlobalKey<NavigatorState> navKey}) {
    _api = api;
    _navKey = navKey;
  }

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Appointment updates and reminders',
      importance: Importance.high,
    );
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _videoChannelId,
        _videoChannelName,
        description: 'Video consultation status updates',
        importance: Importance.max,
      ),
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteOpen);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _cachedToken = token;
      _uploadToken(token);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFromMessage(initial));
    }
  }

  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _navigateByPayload(payload);
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'MEDCLUES';
    final body = notification?.body ?? '';
    final payload = _payloadFromData(message.data);
    final isVideo = message.data['type']?.toString() == 'video_call_status';

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isVideo ? _videoChannelId : _channelId,
          isVideo ? _videoChannelName : _channelName,
          importance: isVideo ? Importance.max : Importance.high,
          priority: isVideo ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  void _handleRemoteOpen(RemoteMessage message) => _openFromMessage(message);

  void _openFromMessage(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    final apptId = message.data['appointmentId']?.toString();
    if (type == 'video_call_status' && apptId != null && apptId.isNotEmpty) {
      final status = message.data['status']?.toString() ?? '';
      if (status == 'accepted') {
        // Join Agora room directly — do not go to waiting room (ctx.go would tear down an active call).
        _go('/video-consult/$apptId');
      } else {
        _go('${RouteNames.appointments}/$apptId');
      }
      return;
    }
    if (apptId != null && apptId.isNotEmpty) {
      _go('${RouteNames.appointments}/$apptId');
      return;
    }
    if (type == 'appointment' ||
        type == 'appointment_cancelled' ||
        type == 'appointment_reminder_24h') {
      _go(RouteNames.appointments);
    }
  }

  String _payloadFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final apptId = data['appointmentId']?.toString();
    if (type == 'video_call_status' && apptId != null && apptId.isNotEmpty) {
      return 'video_call:${data['status']}:$apptId';
    }
    if (apptId != null && apptId.isNotEmpty) return 'appointment:$apptId';
    return type;
  }

  void _navigateByPayload(String payload) {
    if (payload.startsWith('video_call:')) {
      final parts = payload.split(':');
      if (parts.length >= 3) {
        final status = parts[1];
        final id = parts[2];
        if (status == 'accepted') {
          _go('/video-consult/$id');
        } else {
          _go('${RouteNames.appointments}/$id');
        }
      }
      return;
    }
    if (payload.startsWith('appointment:')) {
      final id = payload.split(':').last;
      if (id.isNotEmpty) _go('${RouteNames.appointments}/$id');
      return;
    }
    if (payload == 'appointment' ||
        payload == 'appointment_cancelled' ||
        payload == 'appointment_reminder_24h') {
      _go(RouteNames.appointments);
    }
  }

  void _go(String path) {
    final ctx = _navKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;

    // Do not tear down an active video room when a duplicate FCM arrives.
    if (path.startsWith('/video-consult/')) {
      final apptId = path.replaceFirst('/video-consult/', '').split('?').first;
      final loc = GoRouterState.of(ctx).matchedLocation;
      if (loc == '/video-consult/$apptId') return;
      // Waiting room already navigates when doctor accepts — avoid double route swap.
      if (loc == '/video-waiting/$apptId') return;
    }

    if (path.startsWith('/video-consult/')) {
      final apptId = path.replaceFirst('/video-consult/', '').split('?').first;
      final loc = GoRouterState.of(ctx).matchedLocation;
      if (loc != '/video-consult/$apptId') {
        ctx.pushReplacement('/video-consult/$apptId');
      }
      return;
    }

    ctx.go(path);
  }

  Future<String?> syncTokenWithBackend() async {
    if (!isSupported) return null;
    try {
      await AppPermissionsService.ensureNotifications();
      final token = await FirebaseMessaging.instance.getToken();
      _cachedToken = token;
      if (token != null) await _uploadToken(token);
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token error: $e');
      return null;
    }
  }

  Future<void> _uploadToken(String token) async {
    final api = _api;
    if (api == null) return;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await api.post<Map<String, dynamic>>(
        ApiConfig.userFcmToken,
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FCM upload failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    if (!isSupported) return;
    final api = _api;
    final token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
    if (api != null && token != null) {
      try {
        await api.delete<Map<String, dynamic>>(
          ApiConfig.userFcmToken,
          data: {'token': token},
        );
      } catch (_) {}
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _cachedToken = null;
  }
}
