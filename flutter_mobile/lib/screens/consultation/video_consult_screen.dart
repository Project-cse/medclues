import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../services/agora_session_manager.dart';
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
  static final Set<String> _activeAppointments = {};

  RtcEngine? _engine;
  AgoraJoinCredentials? _creds;
  bool _loading = true;
  bool _disposed = false;
  int _startGeneration = 0;
  String? _error;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoOff = false;
  bool _cameraBlocked = false;
  bool _localPreviewReady = false;
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
  Timer? _chatPollTimer;

  bool _chatOpen = false;
  bool _chatUnread = false;
  int _lastChatId = 0;
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

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
    _statusPollTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
      if (_callEnding || !mounted) return;
      try {
        final status = await ref.read(consultationServiceProvider).fetchVideoCallStatus(widget.appointmentId);
        // Ignore stale ended from a prior attempt until we have joined the channel.
        // While the patient has temporarily left (rejoin screen), still react to a
        // doctor-ended call so they aren't stuck on the rejoin overlay.
        if (status['ended'] == true && _joined) {
          await _handleCallEnded('The doctor ended the consultation.');
          return;
        }
        if (_callStartedAtMs == null && _hadRemote) {
          await _syncCallTimerFromServer();
        }
      } catch (_) {}
    });
  }

  void _startChatPolling() {
    _chatPollTimer?.cancel();
    _fetchChat();
    _chatPollTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (_callEnding || !mounted) return;
      _fetchChat();
    });
  }

  Future<void> _fetchChat() async {
    try {
      final msgs = await ref
          .read(consultationServiceProvider)
          .fetchChatMessages(widget.appointmentId, after: _lastChatId);
      if (!mounted || msgs.isEmpty) return;
      final existingIds = _chatMessages
          .map((e) => (e['id'] is num) ? (e['id'] as num).toInt() : -1)
          .toSet();
      var sawIncoming = false;
      for (final m in msgs) {
        final id = (m['id'] is num) ? (m['id'] as num).toInt() : 0;
        if (id > 0 && existingIds.contains(id)) continue;
        if (id > _lastChatId) _lastChatId = id;
        if ((m['role'] ?? '') != 'patient') sawIncoming = true;
        _chatMessages.add(m);
      }
      setState(() {
        if (sawIncoming && !_chatOpen) _chatUnread = true;
      });
      _scrollChatToEnd();
    } catch (_) {}
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    try {
      final msg = await ref
          .read(consultationServiceProvider)
          .sendChatMessage(widget.appointmentId, text);
      if (!mounted || msg == null) return;
      final id = (msg['id'] is num) ? (msg['id'] as num).toInt() : 0;
      if (id > _lastChatId) _lastChatId = id;
      setState(() => _chatMessages.add(msg));
      _scrollChatToEnd();
    } catch (_) {}
  }

  void _scrollChatToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _handleCallEnded(String message, {bool notifyServer = false}) async {
    if (_callEnding) return;
    _callEnding = true;
    _callTimer?.cancel();
    _statusPollTimer?.cancel();
    _chatPollTimer?.cancel();
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let the route finish building before native Agora starts (avoids Android crash).
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (_alive) await _start();
    });
  }

  bool get _alive => mounted && !_disposed;

  Future<void> _start() async {
    final apptKey = widget.appointmentId;
    if (_activeAppointments.contains(apptKey)) {
      if (_alive) {
        setState(() {
          _loading = false;
          _error = 'Video session is already starting. Go back and try again.';
        });
      }
      return;
    }
    _activeAppointments.add(apptKey);
    final generation = ++_startGeneration;
    AgoraSessionManager.log('PATIENT_CALL_START appt=$apptKey');

    try {
      if (!kIsWeb) {
        final perms = await AppPermissionsService.requireVideoConsult();
        if (!_alive || generation != _startGeneration) return;
        _micGranted = perms.microphone;
        _cameraBlocked = !perms.camera;
      }
      await AgoraSessionManager.release();
      if (!_alive || generation != _startGeneration) return;
      final creds = await ref
          .read(consultationServiceProvider)
          .fetchAgoraToken(widget.appointmentId)
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw Exception(
              'Could not connect. Ensure the doctor accepted the call and you use the same server as the doctor app.',
            ),
          );
      if (!_alive || generation != _startGeneration) return;
      if (creds.appId.isEmpty || creds.token.isEmpty || creds.channel.isEmpty) {
        throw Exception('Invalid video session from server');
      }
      if (creds.uid <= 0) {
        throw Exception('Invalid video session from server (uid)');
      }
      final engine = await AgoraSessionManager.acquire(creds.appId).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Video engine timed out. Check network and try again.'),
      );
      if (!_alive || generation != _startGeneration) {
        await _tearDownEngine(engine);
        return;
      }
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
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableVideo();
      var publishCamera = !_cameraBlocked;
      if (!kIsWeb && publishCamera) {
        try {
          await engine.startPreview();
          _localPreviewReady = true;
        } catch (_) {
          publishCamera = false;
          _cameraBlocked = true;
          _localPreviewReady = false;
        }
      }
      await engine
          .joinChannel(
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
          )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Could not join video channel. Ask the doctor to re-accept the call.');
      });
      AgoraSessionManager.log('PATIENT_JOINED channel=${creds.channel} uid=${creds.uid}');
      if (!kIsWeb) {
        try {
          await engine.setEnableSpeakerphone(_speakerOn);
        } catch (_) {}
      }
      if (!publishCamera) {
        _videoOff = true;
      }

      if (!_alive || generation != _startGeneration) {
        await _tearDownEngine(engine);
        return;
      }
      setState(() {
        _engine = engine;
        _creds = creds;
        _loading = false;
      });
      _startStatusPolling();
      _startChatPolling();
    } on VideoConsultPermissionException catch (e) {
      if (!_alive) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    } catch (e) {
      if (!_alive) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _activeAppointments.remove(apptKey);
    }
  }

  /// Patient taps "End"/back: disconnect locally but DO NOT complete the
  /// consultation on the server, so they can rejoin within their slot if it was
  /// a mistake. The doctor stays in the room and remains in control of ending.
  bool _togglingCamera = false;

  /// Robust camera on/off. Using only muteLocalVideoStream leaves the capture
  /// running and can freeze the last frame; toggling enableLocalVideo actually
  /// stops/starts the camera and re-arms the preview so it never freezes.
  Future<void> _toggleCamera() async {
    if (_togglingCamera) return;
    _togglingCamera = true;
    final engine = _engine;
    final turnOff = !_videoOff;
    try {
      await engine?.muteLocalVideoStream(turnOff);
      await engine?.enableLocalVideo(!turnOff);
      if (!turnOff) {
        _localPreviewReady = true;
        if (!kIsWeb) {
          try {
            await engine?.startPreview();
          } catch (_) {}
        }
      }
    } catch (_) {
    } finally {
      _togglingCamera = false;
      if (mounted) setState(() => _videoOff = turnOff);
    }
  }

  /// Patient exits the room without ending the consultation. The doctor stays
  /// in the room and the patient can rejoin from the appointment card (Join
  /// Video Call) while still within their slot.
  Future<void> _leave() async {
    if (_callEnding) return;
    _callTimer?.cancel();
    _statusPollTimer?.cancel();
    _chatPollTimer?.cancel();
    final engine = _engine;
    _engine = null;
    await _tearDownEngine(engine);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.appointments);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _startGeneration++;
    _activeAppointments.remove(widget.appointmentId);
    _callTimer?.cancel();
    _statusPollTimer?.cancel();
    _chatPollTimer?.cancel();
    _chatController.dispose();
    _chatScroll.dispose();
    if (!_callEnding) {
      unawaited(_tearDownEngine(_engine));
    }
    super.dispose();
  }

  Future<void> _tearDownEngine(RtcEngine? engine) async {
    if (engine == null) return;
    await AgoraSessionManager.release();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: _loading || _error != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_loading && _error == null) {
          _leave();
        }
      },
      child: Scaffold(
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
                      onTap: _toggleCamera,
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
                    _chatControlBtn(),
                    _controlBtn(
                      icon: Icons.call_end,
                      label: l10n.videoEndConsult,
                      color: AppColors.error,
                      onTap: _leave,
                    ),
                  ],
                ),
              ),
            ),
    ),
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
        if (_joined)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: (!_videoOff && _localPreviewReady)
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..scale(-1.0, 1.0),
                          child: AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          ),
                        )
                      : _localVideoOffTile(),
                ),
              ),
            ),
          ),
        if (_chatOpen) _buildChatPanel(),
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
    );
  }

  /// Self-view placeholder shown when the patient turns their camera off so the
  /// card stays visible (with mic state) instead of disappearing.
  Widget _localVideoOffTile() {
    return Container(
      color: const Color(0xFF22223A),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 8),
                Icon(Icons.videocam_off,
                    color: Colors.white.withValues(alpha: 0.85), size: 18),
                const SizedBox(height: 2),
                Text(
                  'You',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          if (_muted)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_off, color: Colors.white, size: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chatControlBtn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: _chatOpen ? AppColors.primary : Colors.white24,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _chatOpen = !_chatOpen;
                    if (_chatOpen) _chatUnread = false;
                  });
                  if (_chatOpen) _scrollChatToEnd();
                },
              ),
            ),
            if (_chatUnread)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Chat', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildChatPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: MediaQuery.of(context).size.height * 0.32,
      child: Material(
        color: const Color(0xFF12121A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Chat with doctor',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => setState(() => _chatOpen = false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet.\nSend a message to your doctor.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScroll,
                      padding: const EdgeInsets.all(14),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, i) {
                        final m = _chatMessages[i];
                        final mine = (m['role'] ?? '') == 'patient';
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              color: mine ? AppColors.primary : Colors.white12,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(mine ? 14 : 2),
                                bottomRight: Radius.circular(mine ? 2 : 14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(
                                    (m['name'] ?? 'Doctor').toString(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                Text(
                                  (m['text'] ?? '').toString(),
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendChat(),
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white10,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendChat,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
