class AppointmentModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String? doctorImageUrl;
  final String slotDate;
  final String slotTime;
  final String status;
  final bool cancelled;
  final bool isCompleted;
  final String? hospitalName;
  final String? location;
  final String? clinicPhone;
  final String? roomNo;
  final double? amount;
  final String? visitType;
  final String? paymentMethod;
  final String? patientName;
  final String? patientRelationship;
  final bool? patientIsSelf;
  final bool graceExtensionUsed;
  final bool paidAtBooking;
  final int? tokenNumber;
  final int? queuePosition;
  final String? bookingId;
  final String? publicId;
  final String? lifecycleStatus;
  final int? visitCount;
  final int? maxVisits;
  final String? validUntil;
  final int? followupVisitsUsed;
  final int? followupVisitsMax;
  final String? followupValidUntil;
  final String? missedAt;
  final String? tomorrowRescheduleDeadline;
  final bool tomorrowRescheduleOffered;
  final bool canConfirmTomorrowReschedule;

  const AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    this.doctorImageUrl,
    required this.slotDate,
    required this.slotTime,
    this.status = 'pending',
    this.cancelled = false,
    this.isCompleted = false,
    this.hospitalName,
    this.location,
    this.clinicPhone,
    this.roomNo,
    this.amount,
    this.visitType,
    this.paymentMethod,
    this.patientName,
    this.patientRelationship,
    this.patientIsSelf,
    this.graceExtensionUsed = false,
    this.paidAtBooking = false,
    this.tokenNumber,
    this.queuePosition,
    this.bookingId,
    this.publicId,
    this.lifecycleStatus,
    this.visitCount,
    this.maxVisits,
    this.validUntil,
    this.followupVisitsUsed,
    this.followupVisitsMax,
    this.followupValidUntil,
    this.missedAt,
    this.tomorrowRescheduleDeadline,
    this.tomorrowRescheduleOffered = false,
    this.canConfirmTomorrowReschedule = false,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final doc = json['docData'] ?? json['doctor'];
    final docMap =
        doc is Map ? Map<String, dynamic>.from(doc) : <String, dynamic>{};
    final addr = docMap['address'];
    String? addrLine1;
    String? addrLine2;
    if (addr is Map) {
      addrLine1 = addr['line1']?.toString().trim();
      addrLine2 = addr['line2']?.toString().trim();
      if (addrLine1 != null && addrLine1.isEmpty) addrLine1 = null;
      if (addrLine2 != null && addrLine2.isEmpty) addrLine2 = null;
    }
    final statusRaw = '${json['status'] ?? 'pending'}'.toLowerCase();
    final cancelled = _isTruthy(json['cancelled']) || statusRaw == 'cancelled';
    final completed = _isTruthy(json['isCompleted'] ?? json['is_completed']) ||
        statusRaw == 'completed';
    return AppointmentModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      doctorId: '${json['docId'] ?? docMap['id'] ?? json['doctorId'] ?? ''}',
      doctorName:
          '${docMap['name'] ?? json['docName'] ?? json['doctorName'] ?? 'Doctor'}',
      specialization:
          '${docMap['speciality'] ?? docMap['specialization'] ?? json['specialization'] ?? json['speciality'] ?? ''}',
      doctorImageUrl: (docMap['image'] ??
              docMap['profile_pic_url'] ??
              json['docImage'] ??
              json['doctorImage'])
          ?.toString(),
      slotDate:
          '${json['slotDate'] ?? json['slot_date'] ?? json['date'] ?? ''}',
      slotTime:
          '${json['slotTime'] ?? json['slot_time'] ?? json['time'] ?? ''}',
      status: statusRaw,
      cancelled: cancelled,
      isCompleted: completed,
      hospitalName: json['hospitalName']?.toString() ??
          docMap['hospitalName']?.toString(),
      location: json['location']?.toString() ?? addrLine1,
      clinicPhone:
          (docMap['phone'] ?? docMap['hospital_contact'] ?? json['clinicPhone'])
              ?.toString(),
      roomNo: json['roomNo']?.toString() ?? addrLine2,
      amount: (json['amount'] ?? json['fees']) is num
          ? ((json['amount'] ?? json['fees']) as num).toDouble()
          : double.tryParse('${json['amount'] ?? json['fees']}'),
      visitType: (json['visitType'] ?? json['visit_type'])?.toString(),
      paymentMethod:
          (json['paymentMethod'] ?? json['payment_method'])?.toString(),
      patientName: _patientNameFromJson(json),
      patientRelationship: _patientRelationshipFromJson(json),
      patientIsSelf: _patientIsSelfFromJson(json),
      graceExtensionUsed: _isTruthy(
          json['graceExtensionUsed'] ?? json['grace_extension_used']),
      paidAtBooking: _isTruthy(json['paidAtBooking'] ??
          json['paid_at_booking'] ??
          json['payment']),
      tokenNumber: (json['tokenNumber'] ?? json['token_number']) is num
          ? ((json['tokenNumber'] ?? json['token_number']) as num).toInt()
          : int.tryParse(
              '${json['tokenNumber'] ?? json['token_number'] ?? ''}'),
      queuePosition: (json['queuePosition'] ?? json['queue_position']) is num
          ? ((json['queuePosition'] ?? json['queue_position']) as num).toInt()
          : int.tryParse(
              '${json['queuePosition'] ?? json['queue_position'] ?? ''}'),
      bookingId: (json['bookingId'] ?? json['booking_id'])?.toString(),
      publicId: (json['publicId'] ?? json['public_id'])?.toString(),
      lifecycleStatus:
          (json['lifecycleStatus'] ?? json['lifecycle_status'])?.toString(),
      visitCount: (json['visitCount'] ?? json['visit_count']) is num
          ? ((json['visitCount'] ?? json['visit_count']) as num).toInt()
          : int.tryParse('${json['visitCount'] ?? json['visit_count'] ?? ''}'),
      maxVisits: (json['maxVisits'] ?? json['max_visits']) is num
          ? ((json['maxVisits'] ?? json['max_visits']) as num).toInt()
          : int.tryParse('${json['maxVisits'] ?? json['max_visits'] ?? ''}'),
      validUntil: (json['validUntil'] ?? json['valid_until'])?.toString(),
      followupVisitsUsed:
          (json['followupVisitsUsed'] ?? json['followup_visits_used']) is num
              ? ((json['followupVisitsUsed'] ?? json['followup_visits_used'])
                      as num)
                  .toInt()
              : null,
      followupVisitsMax: (json['followupVisitsMax'] ??
              json['followup_visits_max']) is num
          ? ((json['followupVisitsMax'] ?? json['followup_visits_max']) as num)
              .toInt()
          : null,
      followupValidUntil:
          (json['followupValidUntil'] ?? json['followup_valid_until'])
              ?.toString(),
      missedAt: (json['missedAt'] ?? json['missed_at'])?.toString(),
      tomorrowRescheduleDeadline: (json['tomorrowRescheduleDeadline'] ??
              json['tomorrow_reschedule_deadline'])
          ?.toString(),
      tomorrowRescheduleOffered: _isTruthy(json['tomorrowRescheduleOffered'] ??
          json['tomorrow_reschedule_offered']),
      canConfirmTomorrowReschedule: _isTruthy(
          json['canConfirmTomorrowReschedule'] ??
              json['can_confirm_tomorrow_reschedule']),
    );
  }

  bool get isUpcoming =>
      !cancelled &&
      !isCompleted &&
      status != 'cancelled' &&
      status != 'completed' &&
      !_terminalLifecycle;

  bool get _terminalLifecycle {
    final ls = (lifecycleStatus ?? '').toUpperCase();
    return {
      'CANCELLED',
      'NO_SHOW',
      'EXPIRED',
      'REFUNDED',
      'CLOSED',
      'FOLLOWUP_EXPIRED',
    }.contains(ls);
  }

  /// Label for list/detail: account holder vs dependent name + relationship.
  String get patientLabel {
    final name = (patientName ?? '').trim();
    final rel = (patientRelationship ?? '').trim();
    if (patientIsSelf == true || patientIsSelf == null) {
      if (name.isEmpty) return 'You';
      return patientIsSelf == true ? 'You · $name' : name;
    }
    if (name.isEmpty) {
      return rel.isNotEmpty ? 'Dependent ($rel)' : 'Dependent';
    }
    if (rel.isNotEmpty) return '$name ($rel)';
    return name;
  }

  bool get isNoShow => (lifecycleStatus ?? '').toUpperCase() == 'NO_SHOW';

  bool get isMissed => (lifecycleStatus ?? '').toUpperCase() == 'MISSED';

  /// Server-backed flag preferred; fall back to local MISSED + offer fields.
  bool get canConfirmTomorrowRescheduleEffective {
    if (canConfirmTomorrowReschedule) return true;
    if (!isMissed || cancelled || isCompleted || !tomorrowRescheduleOffered) {
      return false;
    }
    final raw = tomorrowRescheduleDeadline;
    if (raw == null || raw.isEmpty) return true;
    try {
      final deadline = DateTime.parse(raw.length >= 10 ? raw.substring(0, 10) : raw);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return !today.isAfter(deadline);
    } catch (_) {
      return true;
    }
  }

  bool get canRequestGraceReschedule =>
      !graceExtensionUsed &&
      !cancelled &&
      !isCompleted &&
      paidAtBooking &&
      !isMissed &&
      (isNoShow || isSlotEnded);

  bool get isSlotEnded {
    final end = slotEndDateTime;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  DateTime? get slotEndDateTime {
    final parts = slotDate.split('_');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    var hour = 12;
    var minute = 0;
    final tp = slotTime.split(RegExp(r'[:\-]'));
    if (tp.isNotEmpty) hour = int.tryParse(tp[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 12;
    if (tp.length > 1) minute = int.tryParse(tp[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final lower = slotTime.toLowerCase();
    if (lower.contains('pm') && hour < 12) hour += 12;
    if (lower.contains('am') && hour == 12) hour = 0;
    // Assume ~30 min consultation window after slot start.
    return DateTime(y, m, d, hour, minute).add(const Duration(minutes: 30));
  }

  /// Morning slot → same-day evening suggestion; evening → next day.
  DateTime suggestedGraceDate() {
    final parts = slotDate.split('_');
    final now = DateTime.now();
    var base = DateTime(now.year, now.month, now.day);
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) base = DateTime(y, m, d);
    }
    var hour = 12;
    final tp = slotTime.split(RegExp(r'[:\-]'));
    if (tp.isNotEmpty) {
      hour = int.tryParse(tp[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 12;
    }
    final lower = slotTime.toLowerCase();
    if (lower.contains('pm') && hour < 12) hour += 12;
    if (lower.contains('am') && hour == 12) hour = 0;
    final isMorning = hour < 14;
    if (isMorning) {
      // Prefer same-day evening window → still request next calendar date if past evening.
      final evening = DateTime(base.year, base.month, base.day, 17);
      if (DateTime.now().isBefore(evening)) return base;
      return base.add(const Duration(days: 1));
    }
    return base.add(const Duration(days: 1));
  }

  bool get followupEligible =>
      (lifecycleStatus ?? '').toUpperCase() == 'FOLLOWUP_AVAILABLE';

  bool get isOnlineVisit {
    // Only the visit type decides this — payment method is NOT a proxy
    // (an in-clinic appointment can still be paid online via Razorpay).
    final v = (visitType ?? '').toLowerCase();
    return v.contains('online') || v.contains('video');
  }

  static String? _patientNameFromJson(Map<String, dynamic> json) {
    final ap = json['actualPatient'];
    if (ap is Map) {
      final n = ap['name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
    }
    if (ap is String && ap.trim().isNotEmpty) return ap.trim();
    final direct = json['patientName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final user = json['userData'];
    if (user is Map) {
      final n = user['name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return null;
  }

  static String? _patientRelationshipFromJson(Map<String, dynamic> json) {
    final ap = json['actualPatient'];
    if (ap is Map) {
      final rel = ap['relationship']?.toString().trim();
      if (rel != null && rel.isNotEmpty) return rel;
    }
    return json['patientRelationship']?.toString();
  }

  static bool? _patientIsSelfFromJson(Map<String, dynamic> json) {
    final ap = json['actualPatient'];
    if (ap is Map) {
      final v = ap['isSelf'] ?? ap['is_self'];
      if (v != null) return _isTruthy(v);
      // Name present without isSelf → treat as dependent only when relationship set.
      final rel = (ap['relationship'] ?? '').toString().trim();
      if (rel.isNotEmpty) return false;
      return true;
    }
    // No actualPatient payload: booking for the logged-in account holder.
    return true;
  }

  static bool _isTruthy(dynamic v) {
    if (v == true || v == 1) return true;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }
}
