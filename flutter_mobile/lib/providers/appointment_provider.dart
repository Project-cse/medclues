import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../models/consultation_list_item.dart';
import '../models/slot_model.dart';
import '../services/consultation_service.dart';
import '../services/queue_service.dart';
import 'booking_state_provider.dart';
import 'service_providers.dart';

final upcomingAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).upcoming();
});

final pastAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).past();
});

final cancelledAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).cancelled();
});

final todayAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) async {
  // Floating bar: active upcoming visits (today + future). Date keys from the
  // API are DD_MM_YYYY — parseSlotDateKey handles those for sorting/display.
  final upcoming = await ref.watch(appointmentRepositoryProvider).upcoming();
  final pinnedId = ref.watch(lastBookedAppointmentIdProvider);
  final pendingCancel = ref.watch(optimisticCancelledProvider);
  final active = upcoming
      .where((a) =>
          !pendingCancel.contains(a.id) &&
          a.isUpcoming &&
          !a.cancelled &&
          !a.isCompleted &&
          a.status != 'cancelled' &&
          a.status != 'completed' &&
          !(const {
            'CANCELLED',
            'NO_SHOW',
            'EXPIRED',
            'REFUNDED',
            'CLOSED',
            'FOLLOWUP_EXPIRED',
            'COMPLETED',
          }.contains((a.lifecycleStatus ?? '').toUpperCase())))
      .toList();
  // Surface MISSED offers first so patients can confirm tomorrow reschedule.
  active.sort((a, b) {
    final aMissed = a.isMissed || a.canConfirmTomorrowRescheduleEffective;
    final bMissed = b.isMissed || b.canConfirmTomorrowRescheduleEffective;
    if (aMissed && !bMissed) return -1;
    if (bMissed && !aMissed) return 1;
    // Prefer the appointment just booked so self-book isn't buried behind others.
    if (pinnedId != null && pinnedId.isNotEmpty) {
      if (a.id == pinnedId && b.id != pinnedId) return -1;
      if (b.id == pinnedId && a.id != pinnedId) return 1;
    }
    final da = parseSlotDateKey(a.slotDate) ?? DateTime(9999);
    final db = parseSlotDateKey(b.slotDate) ?? DateTime(9999);
    final byDate = da.compareTo(db);
    if (byDate != 0) return byDate;
    return a.slotTime.compareTo(b.slotTime);
  });
  return active;
});

final userConsultationsProvider =
    FutureProvider.autoDispose<List<ConsultationListItem>>((ref) {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(consultationServiceProvider).fetchUserConsultations();
});

/// Live queue: Socket.IO push + slow HTTP poll fallback (20s).
final liveQueueProvider = StreamProvider.autoDispose
    .family<LiveQueueStatus, String>((ref, appointmentId) async* {
  final service = ref.watch(queueServiceProvider);
  final socket = ref.watch(appSocketServiceProvider);

  Future<LiveQueueStatus?> pull() async {
    try {
      return await service.fetchLiveQueue(appointmentId);
    } catch (_) {
      return null;
    }
  }

  final initial = await pull();
  if (initial != null) yield initial;

  await socket.joinAppointmentQueue(appointmentId);
  final out = StreamController<LiveQueueStatus>();
  final socketSub = socket.queueUpdates(appointmentId).listen((_) async {
    final s = await pull();
    if (s != null && !out.isClosed) out.add(s);
  });
  final timer = Timer.periodic(const Duration(seconds: 20), (_) async {
    final s = await pull();
    if (s != null && !out.isClosed) out.add(s);
  });
  ref.onDispose(() {
    socketSub.cancel();
    timer.cancel();
    out.close();
    unawaited(socket.leaveAppointmentQueue(appointmentId));
  });
  yield* out.stream;
});

final appointmentDetailProvider =
    FutureProvider.autoDispose.family<AppointmentModel, String>((ref, id) {
  return ref.watch(appointmentRepositoryProvider).getById(id);
});

final consultationSummaryProvider = FutureProvider.autoDispose
    .family<ConsultationSummary?, String>((ref, appointmentId) {
  return ref
      .watch(consultationServiceProvider)
      .fetchConsultationSummary(appointmentId);
});

/// Full 5-day schedule — one API call per doctor + mode (reused when switching dates).
final doctorScheduleProvider = FutureProvider.autoDispose
    .family<Map<String, DaySlotsModel>, ({String doctorId, String mode})>(
        (ref, params) {
  return ref
      .watch(appointmentRepositoryProvider)
      .doctorSchedule(params.doctorId, mode: params.mode);
});

/// Warm slot cache while user picks patient / navigates to booking.
void prefetchDoctorSchedule(WidgetRef ref, String doctorId,
    {String mode = 'offline'}) {
  ref.read(doctorScheduleProvider((doctorId: doctorId, mode: mode)).future);
}

final slotsProvider = FutureProvider.autoDispose
    .family<DaySlotsModel, ({String doctorId, String date, String mode})>(
        (ref, params) async {
  final repo = ref.watch(appointmentRepositoryProvider);
  final schedule = await ref.watch(
    doctorScheduleProvider((doctorId: params.doctorId, mode: params.mode))
        .future,
  );
  return repo.dayOf(schedule, params.date) ??
      DaySlotsModel(
          date: params.date, displayDate: params.date, slots: const []);
});

final bookingInProgressProvider = StateProvider<bool>((_) => false);

/// 0 = Upcoming, 1 = Completed, 2 = Cancelled (My Appointments tabs).
final appointmentsTabProvider = StateProvider<int>((_) => 0);

/// IDs the user just cancelled — hidden from the Upcoming list instantly while
/// the (slower) server call + refresh complete in the background.
final optimisticCancelledProvider = StateProvider<Set<String>>((_) => {});

/// Cancel on the server, then refresh the appointment lists. This is meant to
/// run in the background after the UI has already optimistically removed the
/// appointment, so the user never waits on the network.
Future<void> cancelAppointmentAndRefresh(
    WidgetRef ref, String appointmentId) async {
  try {
    await ref.read(appointmentRepositoryProvider).cancel(appointmentId);
  } finally {
    final pinned = ref.read(lastBookedAppointmentIdProvider);
    if (pinned != null && pinned == appointmentId) {
      ref.read(lastBookedAppointmentIdProvider.notifier).state = null;
    }
    ref.invalidate(upcomingAppointmentsProvider);
    ref.invalidate(pastAppointmentsProvider);
    ref.invalidate(cancelledAppointmentsProvider);
    ref.invalidate(todayAppointmentsProvider);
    ref.invalidate(appointmentDetailProvider(appointmentId));
    // Refresh all warm doctor schedule caches so available_count updates.
    ref.invalidate(doctorScheduleProvider);
  }
}
