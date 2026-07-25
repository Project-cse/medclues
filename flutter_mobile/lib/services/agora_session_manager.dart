import 'dart:developer' as dev;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Agora allows only one [RtcEngine] per process. Serialize create/release so
/// rapid route changes (FCM + waiting room) cannot crash the native layer.
class AgoraSessionManager {
  AgoraSessionManager._();

  static final RegExp _appIdPattern = RegExp(r'^[0-9a-f]{32}$');

  static RtcEngine? _engine;
  static Future<void> _releaseFuture = Future.value();

  static void log(String message) {
    dev.log(message, name: 'VideoConsult');
  }

  static String _validateAppId(String appId) {
    final normalized = appId.trim().toLowerCase();
    if (!_appIdPattern.hasMatch(normalized)) {
      throw Exception(
        'Invalid Agora App ID from server. Check AGORA_APP_ID in fastapi_back/.env (32 hex characters).',
      );
    }
    return normalized;
  }

  static Future<RtcEngine> acquire(String appId) async {
    await _releaseFuture;
    if (_engine != null) {
      log('Releasing previous Agora engine before new session');
      await release();
    }

    final normalizedId = _validateAppId(appId);
    final engine = createAgoraRtcEngine();
    try {
      await engine.initialize(
        RtcEngineContext(
          appId: normalizedId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      try {
        await engine.release();
      } catch (_) {}
      rethrow;
    }

    _engine = engine;
    log('Agora engine initialized');
    return engine;
  }

  static Future<void> release() {
    _releaseFuture = _releaseFuture.then((_) async {
      final engine = _engine;
      _engine = null;
      if (engine == null) return;
      try {
        await engine.leaveChannel();
      } catch (_) {}
      try {
        await engine.stopPreview();
      } catch (_) {}
      try {
        await engine.release();
      } catch (_) {}
      // Native SDK needs a beat before createAgoraRtcEngine() again.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      log('Agora engine released');
    });
    return _releaseFuture;
  }
}
