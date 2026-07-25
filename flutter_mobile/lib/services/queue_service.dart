import '../config/api_config.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class LiveQueueStatus {
  const LiveQueueStatus({
    this.tokenNumber,
    this.queuePosition = 0,
    this.patientsAhead = 0,
    this.isNextUp = false,
    this.currentlyServingToken,
    this.doctorStatus = 'in-clinic',
    this.queueTokens = const [],
    this.inactive = false,
    this.lifecycleStatus,
    this.receptionStatus,
  });

  final int? tokenNumber;
  final int queuePosition;
  final int patientsAhead;
  final bool isNextUp;
  final int? currentlyServingToken;
  final String doctorStatus;
  final List<int> queueTokens;
  final bool inactive;
  final String? lifecycleStatus;
  final String? receptionStatus;

  factory LiveQueueStatus.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

    final tokens = <int>[];
    if (json['queueTokens'] is List) {
      for (final t in json['queueTokens'] as List) {
        final n = parseInt(t);
        if (n != null && n > 0) tokens.add(n);
      }
    }

    return LiveQueueStatus(
      tokenNumber: parseInt(json['tokenNumber']),
      queuePosition: parseInt(json['queuePosition']) ?? 0,
      patientsAhead: parseInt(json['patientsAhead']) ?? 0,
      isNextUp: json['isNextUp'] == true,
      currentlyServingToken: parseInt(json['currentlyServingToken']),
      doctorStatus: '${json['doctorStatus'] ?? 'in-clinic'}',
      queueTokens: tokens,
      inactive: json['inactive'] == true,
      lifecycleStatus: json['lifecycleStatus']?.toString(),
      receptionStatus: json['receptionStatus']?.toString(),
    );
  }
}

class QueueService {
  QueueService(this._api);

  final ApiService _api;

  Future<LiveQueueStatus> fetchLiveQueue(String appointmentId) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConfig.appointmentQueueLive(appointmentId),
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not load queue status');
    return LiveQueueStatus.fromJson(data);
  }
}
