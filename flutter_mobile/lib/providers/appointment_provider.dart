import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../models/slot_model.dart';
import 'service_providers.dart';

final upcomingAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).upcoming();
});

final pastAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).past();
});

final cancelledAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).cancelled();
});

final appointmentDetailProvider =
    FutureProvider.autoDispose.family<AppointmentModel, String>((ref, id) {
  return ref.watch(appointmentRepositoryProvider).getById(id);
});

/// Full 5-day schedule — one API call per doctor + mode (reused when switching dates).
final doctorScheduleProvider = FutureProvider.autoDispose
    .family<Map<String, DaySlotsModel>, ({String doctorId, String mode})>((ref, params) {
  return ref
      .watch(appointmentRepositoryProvider)
      .doctorSchedule(params.doctorId, mode: params.mode);
});

/// Warm slot cache while user picks patient / navigates to booking.
void prefetchDoctorSchedule(WidgetRef ref, String doctorId, {String mode = 'offline'}) {
  ref.read(doctorScheduleProvider((doctorId: doctorId, mode: mode)).future);
}

final slotsProvider = FutureProvider.autoDispose
    .family<DaySlotsModel, ({String doctorId, String date, String mode})>((ref, params) async {
  final schedule = await ref.watch(
    doctorScheduleProvider((doctorId: params.doctorId, mode: params.mode)).future,
  );
  return schedule[params.date] ??
      DaySlotsModel(date: params.date, displayDate: params.date, slots: const []);
});

final bookingInProgressProvider = StateProvider<bool>((_) => false);

/// 0 = Upcoming, 1 = Completed, 2 = Cancelled (My Appointments tabs).
final appointmentsTabProvider = StateProvider<int>((_) => 0);

/// Cancel on server, refresh lists, ready for UI to switch to Cancelled tab.
Future<void> cancelAppointmentAndRefresh(WidgetRef ref, String appointmentId) async {
  await ref.read(appointmentRepositoryProvider).cancel(appointmentId);
  ref.invalidate(upcomingAppointmentsProvider);
  ref.invalidate(pastAppointmentsProvider);
  ref.invalidate(cancelledAppointmentsProvider);
  ref.invalidate(appointmentDetailProvider(appointmentId));
  await Future.wait([
    ref.refresh(upcomingAppointmentsProvider.future),
    ref.refresh(cancelledAppointmentsProvider.future),
  ]);
}
