import 'dart:developer' as dev;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Agora allows only one [RtcEngine] per process. Serialize create/release so
/// rapid route changes (FCM + waiting room) cannot crash the native layer.
class AgoraSessionManager {
  AgoraSessionManager._();

  static RtcEngine? _engine;
  static Future<void> _releaseFuture = Future.value();

  static void log(String message) {
    dev.log(message, name: 'VideoConsult');
  }

  static Future<RtcEngine> acquire(String appId) async {
    await _releaseFuture;
    if (_engine != null) {
      log('Releasing previous Agora engine before new session');
      await release();
    }
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
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
        await engine.release();
      } catch (_) {}
      // Native SDK needs a beat before createAgoraRtcEngine() again.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      log('Agora engine released');
    });
    return _releaseFuture;
  }
}
