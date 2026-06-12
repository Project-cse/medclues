import '../config/api_config.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class AgoraJoinCredentials {
  const AgoraJoinCredentials({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    this.consultationId,
    this.callStartedAtMs,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final int? consultationId;
  final int? callStartedAtMs;

  factory AgoraJoinCredentials.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    final uid = (json['uid'] is num)
        ? (json['uid'] as num).toInt()
        : int.tryParse('${json['uid']}') ?? 0;
    if (uid <= 0) {
      throw Exception('Invalid video session: missing Agora user id from server');
    }

    return AgoraJoinCredentials(
      appId: '${json['appId'] ?? json['app_id'] ?? ''}',
      channel: '${json['channel'] ?? json['channelName'] ?? ''}',
      token: '${json['token'] ?? ''}',
      uid: uid,
      consultationId: parseInt(json['consultationId'] ?? json['consultation_id']),
      callStartedAtMs: parseInt(json['callStartedAt'] ?? json['call_started_at']),
    );
  }
}

class CallSessionStatus {
  const CallSessionStatus({
    required this.status,
    this.sessionId,
    this.canJoin = false,
    this.rejectReason,
    this.patientName,
    this.tokenNumber,
    this.queuePosition,
  });

  final String status;
  final int? sessionId;
  final bool canJoin;
  final String? rejectReason;
  final String? patientName;
  final int? tokenNumber;
  final int? queuePosition;

  factory CallSessionStatus.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

    return CallSessionStatus(
      status: '${json['status'] ?? 'none'}',
      sessionId: parseInt(json['sessionId'] ?? json['session_id']),
      canJoin: json['canJoin'] == true,
      rejectReason: json['rejectReason']?.toString(),
      patientName: json['patientName']?.toString(),
      tokenNumber: parseInt(json['tokenNumber']),
      queuePosition: parseInt(json['queuePosition']),
    );
  }
}

class ConsultationService {
  ConsultationService(this._api);

  final ApiService _api;

  Future<CallSessionStatus> requestCall(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.callRequestForAppointment(appointmentId),
      data: {},
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not request video consultation');
    return CallSessionStatus.fromJson(data);
  }

  Future<CallSessionStatus> fetchCallStatus(String appointmentId) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConfig.callStatusForAppointment(appointmentId),
    );
    final data = res.data ?? {};
    if (data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'Could not load call status');
    }
    return CallSessionStatus.fromJson(data);
  }

  Future<void> cancelCallRequest(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.callCancelForAppointment(appointmentId),
      data: {},
    );
    assertSuccess(res.data ?? {}, 'Could not cancel call request');
  }

  Future<AgoraJoinCredentials> fetchAgoraToken(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.agoraTokenForAppointment(appointmentId),
      data: {},
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not start video call');
    return AgoraJoinCredentials.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchVideoCallStatus(String appointmentId) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConfig.videoCallStatusForAppointment(appointmentId),
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> syncCallTimer(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.syncCallTimerForAppointment(appointmentId),
      data: {},
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> endVideoCall(String appointmentId, {int? consultationId}) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.endVideoCallForAppointment(appointmentId),
      data: {
        if (consultationId != null) 'consultationId': consultationId,
      },
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not end video call');
    return data;
  }
}
