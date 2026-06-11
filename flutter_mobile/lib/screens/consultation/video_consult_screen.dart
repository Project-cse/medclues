import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/service_providers.dart';
import '../../services/app_permissions_service.dart';
import '../../services/consultation_service.dart';
import '../../widgets/animations/connecting_doctor_overlay.dart';

/// Agora RTC video room for an online appointment.
class VideoConsultScreen extends ConsumerStatefulWidget {
  const VideoConsultScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<VideoConsultScreen> createState() => _VideoConsultScreenState();
}

class _VideoConsultScreenState extends ConsumerState<VideoConsultScreen> {
  RtcEngine? _engine;
  AgoraJoinCredentials? _creds;
  bool _loading = true;
  String? _error;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoOff = false;
  bool _cameraBlocked = false;
  bool _speakerOn = true;
  bool _micGranted = true;
  int _callSeconds = 0;
  int? _callStartedAtMs;
  bool _hadRemote = false;
  int? _remoteJoinedAtMs;
  bool _callEnding = false;
  String? _callEndedMessage;
  Timer? _callTimer;
  Timer? _statusPollTimer;

  String get _callDurationLabel {
    final m = _callSeconds ~/ 60;
    final s = _callSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startCallTimer() {
    if (_callStartedAtMs == null) return;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartedAtMs == null) return;
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _callStartedAtMs!) / 1000).floor();
      setState(() => _callSeconds = elapsed < 0 ? 0 : elapsed);
    });
  }

  Future<void> _syncCallTimerFromServer() async {
    if (_callEnding) return;
    try {
      final status = await ref.read(consultationServiceProvider).syncCallTimer(widget.appointmentId);
      final raw = status['callStartedAt'];
      if (raw == null) return;
      final parsed = raw is num ? raw.toInt() : int.tryParse('$raw');
      if (parsed == null || parsed <= 0) return;
      _callStartedAtMs = parsed;
      _startCallTimer();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_callEnding || !mounted) return;
      try {
        final status = await ref.read(consultationServiceProvider).fetchVideoCallStatus(widget.appointmentId);
        // Ignore stale ended from a prior attempt until we have joined the channel.
        if (status['ended'] == true && _joined) {
          await _handleCallEnded('The call was ended.');
          return;
        }
        if (_callStartedAtMs == null && _hadRemote) {
          await _syncCallTimerFromServer();
        }
      } catch (_) {}
    });
  }

  Future<void> _handleCallEnded(String message, {bool notifyServer = false}) async {
    if (_callEnding) return;
    _callEnding = true;
    _callTimer?.cancel();
    _statusPollTimer?.cancel();
    if (mounted) setState(() => _callEndedMessage = message);

    if (notifyServer) {
      try {
        await ref.read(consultationServiceProvider).endVideoCall(
              widget.appointmentId,
              consultationId: _creds?.consultationId,
            );
      } catch (_) {}
    }

    final engine = _engine;
    _engine = null;
    await _tearDownEngine(engine);

    if (mounted) {
      context.pushReplacement(
        '/consultation-summary/${widget.appointmentId}?seconds=$_callSeconds',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      if (!kIsWeb) {
        final perms = await AppPermissionsService.requireVideoConsult();
        _micGranted = perms.microphone;
        _cameraBlocked = !perms.camera;
      }
      final creds = await ref.read(consultationServiceProvider).fetchAgoraToken(widget.appointmentId);
      if (creds.appId.isEmpty || creds.token.isEmpty || creds.channel.isEmpty) {
        throw Exception('Invalid video session from server');
      }
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: creds.appId));
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (mounted) setState(() => _joined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (mounted) {
              _hadRemote = true;
              _remoteJoinedAtMs = DateTime.now().millisecondsSinceEpoch;
              setState(() => _remoteUid = remoteUid);
            }
            _syncCallTimerFromServer();
          },
          onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
            if (mounted &&
                (state == RemoteVideoState.remoteVideoStateStarting ||
                    state == RemoteVideoState.remoteVideoStateDecoding)) {
              setState(() => _remoteUid = remoteUid);
            }
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted || !_hadRemote) return;
            final joinedAt = _remoteJoinedAtMs;
            if (joinedAt != null &&
                DateTime.now().millisecondsSinceEpoch - joinedAt < 4000) {
              return;
            }
            if (_remoteUid == remoteUid || _hadRemote) {
              _handleCallEnded('The call was ended.');
            }
          },
          onError: (err, msg) {
            if (mounted) setState(() => _error = 'Call error ($err): $msg');
          },
        ),
      );
      await engine.enableVideo();
      var publishCamera = !_cameraBlocked;
      if (!kIsWeb && publishCamera) {
        try {
          await engine.startPreview();
        } catch (_) {
          publishCamera = false;
          _cameraBlocked = true;
        }
      }
      if (!kIsWeb) {
        await engine.setEnableSpeakerphone(_speakerOn);
      }
      await engine.joinChannel(
        token: creds.token,
        channelId: creds.channel,
        uid: creds.uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: publishCamera,
          publishMicrophoneTrack: _micGranted,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
      if (!publishCamera) {
        _videoOff = true;
      }

      if (!mounted) return;
      setState(() {
        _engine = engine;
        _creds = creds;
        _loading = false;
      });
      _startStatusPolling();
    } on VideoConsultPermissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _leave() async {
    await _handleCallEnded('You ended the call.', notifyServer: true);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _statusPollTimer?.cancel();
    if (!_callEnding) {
      _tearDownEngine(_engine);
    }
    super.dispose();
  }

  Future<void> _tearDownEngine(RtcEngine? engine) async {
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.videoConsult, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            if (!_loading && _error == null)
              Text(
                _callStartedAtMs != null
                    ? 'Call time $_callDurationLabel'
                    : (_joined ? l10n.videoWaitingDoctor : l10n.videoConnecting),
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _leave,
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlBtn(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      label: _muted ? l10n.videoUnmute : l10n.videoMute,
                      onTap: () async {
                        await _engine?.muteLocalAudioStream(!_muted);
                        setState(() => _muted = !_muted);
                      },
                    ),
                    _controlBtn(
                      icon: _videoOff ? Icons.videocam_off : Icons.videocam,
                      label: _videoOff ? l10n.videoCameraOn : l10n.videoCameraOff,
                      onTap: () async {
                        await _engine?.muteLocalVideoStream(!_videoOff);
                        setState(() => _videoOff = !_videoOff);
                      },
                    ),
                    _controlBtn(
                      icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                      label: _speakerOn ? 'Speaker' : 'Earpiece',
                      onTap: () async {
                        final next = !_speakerOn;
                        await _engine?.setEnableSpeakerphone(next);
                        setState(() => _speakerOn = next);
                      },
                    ),
                    _controlBtn(
                      icon: Icons.call_end,
                      label: l10n.videoEndConsult,
                      color: AppColors.error,
                      onTap: _leave,
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.25, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading) {
      return const ConnectingDoctorOverlay();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (_error!.toLowerCase().contains('createirisapiengine') ||
                  _error!.toLowerCase().contains('initirisrtc'))
                Text(
                  'Flutter Web needs iris-web-rtc in web/index.html. Stop the app completely and run flutter run -d chrome again (hot reload is not enough).',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                )
              else if (_error!.toLowerCase().contains('agora') ||
                  _error!.toLowerCase().contains('token'))
                Text(
                  'Check AGORA_APP_ID and AGORA_APP_CERTIFICATE in fastapi_back/.env, then restart the API.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.videoGoBack, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (kIsWeb && _cameraBlocked)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Material(
              color: Colors.amber.shade900.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Camera may be in use by the doctor tab. Close doctor camera or use phone + laptop for full video test.',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
          ),
        if (_remoteUid != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: _creds!.channel),
            ),
          )
        else
          ColoredBox(
            color: const Color(0xFF1A1A2E),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _joined ? Icons.person_search : Icons.wifi_tethering,
                    color: Colors.white54,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _joined ? l10n.videoWaiting : l10n.videoConnecting,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.videoChannel}: ${_creds?.channel ?? ''}',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        if (!_videoOff)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: engine,
                        canvas: VideoCanvas(uid: _creds?.uid ?? 0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_callEndedMessage != null)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.85),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call_end, color: Colors.redAccent, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    l10n.videoEndCall,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _callEndedMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    )
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOut);
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color ?? Colors.white24,
          shape: const CircleBorder(),
          child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
