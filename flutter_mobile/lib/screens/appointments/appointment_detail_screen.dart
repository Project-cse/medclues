import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../services/app_permissions_service.dart';
import '../../utils/calendar_helper.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/appointment_status_utils.dart';
import '../../utils/vc_slot_window.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/appointment_action_buttons.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/appointment_status_chip.dart';
import '../../widgets/appointments/live_queue_panel.dart';
import '../../widgets/common/avatar_image.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Matches mobile/app/(patient)/appointment-detail.tsx
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  String _doctorDisplayName(String name) {
    final n = name.trim();
    if (n.toLowerCase().startsWith('dr.')) return n;
    if (n.toLowerCase().startsWith('dr ')) return n;
    return n;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appt = ref.watch(appointmentDetailProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointmentsDetailsTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: appt.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (a) {
          final isUpcoming = a.isUpcoming;
          final isCompleted = a.isCompleted;
          final liveQueue = isUpcoming && isAppointmentToday(a.slotDate)
              ? ref.watch(liveQueueProvider(a.id)).valueOrNull
              : null;
          final liveLifecycle =
              (liveQueue?.receptionStatus ?? '').toUpperCase() ==
                      'READY_FOR_DOCTOR'
                  ? 'CHECKED_IN'
                  : liveQueue?.lifecycleStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AvatarImage(uri: a.doctorImageUrl, size: 72),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _doctorDisplayName(a.doctorName),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (a.specialization.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    a.specialization,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                AppointmentStatusChip(
                                  appointment: a,
                                  isNextUp: liveQueue?.isNextUp == true,
                                  lifecycleStatus: liveLifecycle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      if (!a.cancelled) ...[
                        _AppointmentLifecycleTimeline(
                          appointment: a,
                          isNextUp: liveQueue?.isNextUp == true,
                          lifecycleStatus: liveLifecycle,
                          receptionStatus: liveQueue?.receptionStatus,
                        ),
                        const Divider(height: 32),
                      ],
                      _detailRow(
                        Icons.person_outline,
                        'Patient',
                        a.patientLabel,
                      ),
                      _detailRow(
                        Icons.calendar_today_outlined,
                        l10n.receiptDateTime,
                        '${DateFormatter.formatSlotDate(a.slotDate)} • ${DateFormatter.displayTime(a.slotTime)}',
                      ),
                      if (a.hospitalName != null && a.hospitalName!.isNotEmpty)
                        _detailRow(Icons.local_hospital_outlined,
                            l10n.receiptHospital, a.hospitalName!),
                      if (a.location != null && a.location!.isNotEmpty)
                        _detailRow(Icons.location_on_outlined,
                            l10n.receiptLocation, a.location!),
                      if (a.amount != null)
                        _detailRow(Icons.payments_outlined, l10n.doctorFees,
                            CurrencyFormatter.format(a.amount!)),
                      if (a.publicId != null && a.publicId!.isNotEmpty)
                        _detailRow(Icons.badge_outlined, 'Appointment ID',
                            a.publicId!.toUpperCase()),
                      if (a.bookingId != null && a.bookingId!.isNotEmpty)
                        _detailRow(Icons.qr_code_2, l10n.receiptBookingId,
                            a.bookingId!.toUpperCase()),
                      if (a.tokenNumber != null && a.tokenNumber! > 0)
                        _detailRow(Icons.confirmation_number_outlined,
                            l10n.receiptToken, '#${a.tokenNumber}'),
                      if (isUpcoming) LiveQueuePanel(appointment: a),
                      if (isUpcoming) ...[
                        AppointmentActionButtons(
                            appointment: a, compact: false),
                        const SizedBox(height: 12),
                      ],
                      if (a.isOnlineVisit && isUpcoming) ...[
                        const SizedBox(height: 20),
                        Builder(builder: (context) {
                          final window = VcSlotWindow.fromSlot(
                            slotDate: a.slotDate,
                            slotTime: a.slotTime,
                          );
                          final canJoin = window.canJoinWindow && !window.forceEnd;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (window.windowMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    window.windowMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              AppButton(
                                label: window.joinButtonLabel,
                                onPressed: !canJoin
                                    ? null
                                    : () async {
                                        try {
                                          await AppPermissionsService.requireVideoConsult();
                                        } on VideoConsultPermissionException catch (e) {
                                          if (!context.mounted) return;
                                          AppSnackbar.show(context, e.toString());
                                          return;
                                        }
                                        if (!context.mounted) return;
                                        context.push('/video-waiting/${a.id}');
                                      },
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                      if (isUpcoming) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          label: l10n.appointmentsAddToCalendar,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok =
                                await CalendarHelper.addAppointmentToCalendar(
                                    a);
                            if (!context.mounted) return;
                            AppSnackbar.show(
                              context,
                              ok
                                  ? l10n.appointmentsCalendarAdded
                                  : l10n.appointmentsCalendarFailed,
                              success: ok,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: l10n.appointmentsCancel,
                          variant: AppButtonVariant.danger,
                          onPressed: () async {
                            try {
                              ref
                                  .read(optimisticCancelledProvider.notifier)
                                  .update((s) => {...s, a.id});
                              ref.invalidate(todayAppointmentsProvider);
                              await cancelAppointmentAndRefresh(ref, a.id);
                              if (!context.mounted) return;
                              ref.read(appointmentsTabProvider.notifier).state =
                                  2;
                              context.go(RouteNames.appointments);
                              AppSnackbar.show(
                                  context, l10n.appointmentsCancelledSuccess,
                                  success: true);
                            } catch (e) {
                              ref
                                  .read(optimisticCancelledProvider.notifier)
                                  .update((s) => {...s}..remove(a.id));
                              if (context.mounted) {
                                AppSnackbar.show(
                                    context,
                                    e
                                        .toString()
                                        .replaceFirst('Exception: ', ''));
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (a.canConfirmTomorrowRescheduleEffective) ...[
                        const SizedBox(height: 8),
                        _TomorrowRescheduleButton(appointment: a),
                        const SizedBox(height: 12),
                      ] else if (a.canRequestGraceReschedule) ...[
                        const SizedBox(height: 8),
                        _GraceRescheduleButton(appointment: a),
                        const SizedBox(height: 12),
                      ],
                      AppButton(
                        label: l10n.receiptAppointmentReceipt,
                        variant: AppButtonVariant.secondary,
                        onPressed: () =>
                            context.push('/booking/receipt/${a.id}'),
                      ),
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 16),
                  if (a.bookingId != null &&
                      a.bookingId!.isNotEmpty &&
                      (a.summaryQrUrl ?? '').isNotEmpty)
                    _VisitSummaryQrCard(
                      bookingId: a.bookingId!,
                      summaryQrUrl: a.summaryQrUrl!,
                    ),
                  if (a.bookingId != null &&
                      a.bookingId!.isNotEmpty &&
                      (a.summaryQrUrl ?? '').isNotEmpty)
                    const SizedBox(height: 16),
                  _ConsultationSummarySection(appointmentId: appointmentId),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.specCircleFill),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TomorrowRescheduleButton extends ConsumerStatefulWidget {
  const _TomorrowRescheduleButton({required this.appointment});

  final AppointmentModel appointment;

  @override
  ConsumerState<_TomorrowRescheduleButton> createState() =>
      _TomorrowRescheduleButtonState();
}

class _TomorrowRescheduleButtonState
    extends ConsumerState<_TomorrowRescheduleButton> {
  bool _submitting = false;

  Future<void> _submit() async {
    final a = widget.appointment;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateLabel =
        '${tomorrow.day.toString().padLeft(2, '0')}/'
        '${tomorrow.month.toString().padLeft(2, '0')}/'
        '${tomorrow.year}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reschedule for tomorrow',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Your appointment was missed. Confirm to move it to tomorrow '
          '($dateLabel) with the same doctor. '
          'If you do not confirm by midnight tonight, it will be cancelled.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm tomorrow'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(appointmentServiceProvider)
          .confirmTomorrowReschedule(a.id, requestedDate: tomorrow);
      ref.invalidate(appointmentDetailProvider(a.id));
      ref.invalidate(upcomingAppointmentsProvider);
      ref.invalidate(pastAppointmentsProvider);
      ref.invalidate(todayAppointmentsProvider);
      if (!mounted) return;
      final msg = result['message']?.toString() ??
          'Appointment rescheduled for tomorrow';
      AppSnackbar.show(context, msg, success: true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Reschedule for tomorrow',
      loading: _submitting,
      onPressed: _submitting ? null : _submit,
    );
  }
}

class _GraceRescheduleButton extends ConsumerStatefulWidget {
  const _GraceRescheduleButton({required this.appointment});

  final AppointmentModel appointment;

  @override
  ConsumerState<_GraceRescheduleButton> createState() =>
      _GraceRescheduleButtonState();
}

class _GraceRescheduleButtonState extends ConsumerState<_GraceRescheduleButton> {
  bool _submitting = false;

  Future<void> _submit() async {
    final a = widget.appointment;
    final suggested = a.suggestedGraceDate();
    final dateLabel =
        '${suggested.day.toString().padLeft(2, '0')}/'
        '${suggested.month.toString().padLeft(2, '0')}/'
        '${suggested.year}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request reschedule',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Your consultation slot has ended. Request reception to move this '
          'appointment to $dateLabel (morning → evening/next day, evening → next day). '
          'Reception will check availability and confirm.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(appointmentServiceProvider)
          .requestGraceReschedule(a.id, requestedDate: suggested);
      ref.invalidate(appointmentDetailProvider(a.id));
      ref.invalidate(upcomingAppointmentsProvider);
      ref.invalidate(pastAppointmentsProvider);
      ref.invalidate(todayAppointmentsProvider);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        'Reschedule request sent to reception',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Request reschedule (missed slot)',
      loading: _submitting,
      onPressed: _submitting ? null : _submit,
    );
  }
}

class _AppointmentLifecycleTimeline extends StatelessWidget {
  const _AppointmentLifecycleTimeline({
    required this.appointment,
    required this.isNextUp,
    this.lifecycleStatus,
    this.receptionStatus,
  });

  final AppointmentModel appointment;
  final bool isNextUp;
  final String? lifecycleStatus;
  final String? receptionStatus;

  int get _activeStep {
    final lifecycle =
        (lifecycleStatus ?? appointment.lifecycleStatus ?? '').toUpperCase();
    final reception = (receptionStatus ?? '').toUpperCase();
    final status = appointment.status.toLowerCase();
    if (appointment.isCompleted ||
        status == 'completed' ||
        lifecycle == 'COMPLETED' ||
        lifecycle == 'CLOSED') {
      return 5;
    }
    if (lifecycle == 'IN_PROGRESS' ||
        lifecycle == 'IN_CONSULTATION' ||
        status == 'in-consult') {
      return 4;
    }
    if (isNextUp ||
        lifecycle == 'READY_FOR_DOCTOR' ||
        reception == 'READY_FOR_DOCTOR') {
      return 3;
    }
    if (lifecycle == 'CHECKED_IN' || status == 'in-queue') {
      return 2;
    }
    if (lifecycle == 'CONFIRMED' ||
        status == 'confirmed' ||
        reception == 'VERIFIED') {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      'Booked',
      'Confirmed',
      appointment.tokenNumber != null && appointment.tokenNumber! > 0
          ? 'Checked in • Token #${appointment.tokenNumber}'
          : 'Checked in',
      'Ready for doctor',
      'In progress',
      'Completed',
    ];
    final active = _activeStep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment progress',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < steps.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= active
                          ? (index == active
                              ? AppColors.logoTeal
                              : const Color(0xFF16A34A))
                          : Colors.grey.shade300,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 24,
                      color: index < active
                          ? const Color(0xFF16A34A)
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  steps[index],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        index == active ? FontWeight.w700 : FontWeight.w500,
                    color: index <= active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ConsultationSummarySection extends ConsumerWidget {
  const _ConsultationSummarySection({required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(consultationSummaryProvider(appointmentId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: summary.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => Text(
          'Could not load prescription. Pull to refresh or try again later.',
          style:
              GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        data: (s) {
          if (s == null || !s.hasContent) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'No prescription added yet. Your doctor may update this after the consultation.',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prescription & consultation notes',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (s.diagnosis != null && s.diagnosis!.trim().isNotEmpty)
                _summaryBlock('Diagnosis', s.diagnosis!),
              if (s.prescription != null && s.prescription!.trim().isNotEmpty)
                _summaryBlock('Prescription', s.prescription!),
              if (s.notes != null && s.notes!.trim().isNotEmpty)
                _summaryBlock('Notes', s.notes!),
              if (s.advice != null && s.advice!.trim().isNotEmpty)
                _summaryBlock('Advice', s.advice!),
              if (s.followupDate != null && s.followupDate!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Follow-up: ${s.followupDate}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.logoTeal),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryBlock(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.logoTeal),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.poppins(
                fontSize: 14, height: 1.45, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _VisitSummaryQrCard extends StatelessWidget {
  const _VisitSummaryQrCard({
    required this.bookingId,
    required this.summaryQrUrl,
  });

  final String bookingId;
  final String summaryQrUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(
            'Visit summary',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Not for reception check-in — phone camera opens your appointment details',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          QrImageView(
            data: summaryQrUrl,
            size: 168,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            padding: const EdgeInsets.all(8),
          ),
          const SizedBox(height: 8),
          Text(
            bookingId.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.logoTeal,
            ),
          ),
        ],
      ),
    );
  }
}
