/// Client-side helpers for video-consult join window (mirrors server IST logic).
class VcSlotWindow {
  const VcSlotWindow({
    this.slotStartAt,
    this.slotEndAt,
    this.graceEndsAt,
    this.joinOpensAt,
    this.canJoinWindow = true,
    this.inGrace = false,
    this.softWarn = false,
    this.forceEnd = false,
    this.windowMessage,
  });

  final DateTime? slotStartAt;
  final DateTime? slotEndAt;
  final DateTime? graceEndsAt;
  final DateTime? joinOpensAt;
  final bool canJoinWindow;
  final bool inGrace;
  final bool softWarn;
  final bool forceEnd;
  final String? windowMessage;

  static const slotMinutes = 15;
  static const earlyGraceMinutes = 1;
  static const lateGraceMinutes = 5;
  static const softWarnBeforeEndMinutes = 2;

  factory VcSlotWindow.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VcSlotWindow();
    DateTime? ms(dynamic v) {
      if (v == null) return null;
      final n = v is num ? v.toInt() : int.tryParse('$v');
      if (n == null || n <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(n);
    }

    return VcSlotWindow(
      slotStartAt: ms(json['slotStartAt'] ?? json['slot_start_at']),
      slotEndAt: ms(json['slotEndAt'] ?? json['slot_end_at']),
      graceEndsAt: ms(json['graceEndsAt'] ?? json['grace_ends_at']),
      joinOpensAt: ms(json['joinOpensAt'] ?? json['join_opens_at']),
      canJoinWindow: json['canJoinWindow'] != false,
      inGrace: json['inGrace'] == true,
      softWarn: json['softWarn'] == true,
      forceEnd: json['forceEnd'] == true,
      windowMessage: json['windowMessage']?.toString() ?? json['window_message']?.toString(),
    );
  }

  /// Compute from appointment slot_date / slot_time when server window is absent.
  factory VcSlotWindow.fromSlot({
    required String slotDate,
    required String slotTime,
    DateTime? now,
  }) {
    final bounds = parseSlotBounds(slotDate, slotTime);
    if (bounds == null) return const VcSlotWindow();
    final start = bounds.$1;
    final end = bounds.$2;
    final n = now ?? DateTime.now();
    final joinOpens = start.subtract(const Duration(minutes: earlyGraceMinutes));
    final graceEnds = end.add(const Duration(minutes: lateGraceMinutes));
    final softAt = end.subtract(const Duration(minutes: softWarnBeforeEndMinutes));
    final force = !n.isBefore(graceEnds);
    final grace = !n.isBefore(end) && n.isBefore(graceEnds);
    final soft = !force && !n.isBefore(softAt);
    final canJoin = !n.isBefore(joinOpens) && n.isBefore(graceEnds);

    String? message;
    if (n.isBefore(joinOpens)) {
      message = 'Join opens at ${_fmtTime(start)}';
    } else if (force) {
      message = 'This slot has ended';
    } else if (grace) {
      message = 'Slot ended. Grace period — finish or leave soon.';
    } else if (soft) {
      message = 'Consultation ends in 2 minutes.';
    }

    return VcSlotWindow(
      slotStartAt: start,
      slotEndAt: end,
      graceEndsAt: graceEnds,
      joinOpensAt: joinOpens,
      canJoinWindow: canJoin,
      inGrace: grace,
      softWarn: soft,
      forceEnd: force,
      windowMessage: message,
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final mer = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $mer';
  }

  static (DateTime, DateTime)? parseSlotBounds(String slotDate, String slotTime) {
    final day = _parseLegacyDate(slotDate);
    if (day == null) return null;
    final raw = slotTime.trim();
    if (raw.isEmpty) return null;

    final parts = raw.split(RegExp(r'\s*[-–—]\s*'));
    final startClock = _parseClock(parts.first);
    if (startClock == null) return null;
    final start = DateTime(day.year, day.month, day.day, startClock.$1, startClock.$2);

    DateTime? end;
    if (parts.length > 1) {
      final endClock = _parseClock(parts[1]);
      if (endClock != null) {
        end = DateTime(day.year, day.month, day.day, endClock.$1, endClock.$2);
        if (!end.isAfter(start)) {
          end = end.add(const Duration(days: 1));
        }
      }
    }
    end ??= start.add(const Duration(minutes: slotMinutes));
    return (start, end);
  }

  static DateTime? _parseLegacyDate(String slotDate) {
    final raw = slotDate.trim().replaceAll('/', '_').replaceAll('-', '_');
    final parts = raw.split('_');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  static (int, int)? _parseClock(String text) {
    final s = text.trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'(\d{1,2})\s*:\s*(\d{2})\s*(AM|PM|am|pm)?').firstMatch(s);
    if (m != null) {
      var hour = int.parse(m.group(1)!);
      final minute = int.parse(m.group(2)!);
      final mer = (m.group(3) ?? '').toUpperCase();
      if (mer == 'PM' && hour < 12) hour += 12;
      if (mer == 'AM' && hour == 12) hour = 0;
      return (hour, minute);
    }
    final m2 = RegExp(r'(\d{1,2})\s*(AM|PM|am|pm)').firstMatch(s);
    if (m2 != null) {
      var hour = int.parse(m2.group(1)!);
      final mer = m2.group(2)!.toUpperCase();
      if (mer == 'PM' && hour < 12) hour += 12;
      if (mer == 'AM' && hour == 12) hour = 0;
      return (hour, 0);
    }
    return null;
  }

  String get joinButtonLabel {
    if (forceEnd) return 'Slot ended';
    if (!canJoinWindow && joinOpensAt != null) {
      final mins = joinOpensAt!.difference(DateTime.now()).inMinutes;
      if (mins > 0) return 'Opens in ${mins}m';
      return 'Join opens soon';
    }
    return 'Join Video Call';
  }

  String leaveConfirmMessage() {
    final end = slotEndAt;
    if (end == null) {
      return 'Leave the call? You can rejoin until the slot ends.';
    }
    return 'Leave the call? You can rejoin until ${_fmtTime(end)}.';
  }
}
