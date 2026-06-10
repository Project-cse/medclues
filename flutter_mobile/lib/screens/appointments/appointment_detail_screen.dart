import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/calendar_helper.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/avatar_image.dart';

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
        title: Text(l10n.appointmentsDetailsTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: appt.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (a) {
          final isUpcoming = a.isUpcoming;
          final statusLabel = a.cancelled
              ? l10n.appointmentsCancelled
              : a.isCompleted
                  ? l10n.appointmentsCompleted
                  : l10n.appointmentsUpcoming;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                            if (isUpcoming) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.appointmentsUpcoming,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    l10n.receiptDateTime,
                    '${DateFormatter.formatSlotDate(a.slotDate)} • ${DateFormatter.displayTime(a.slotTime)}',
                  ),
                  if (a.hospitalName != null && a.hospitalName!.isNotEmpty)
                    _detailRow(Icons.local_hospital_outlined, l10n.receiptHospital, a.hospitalName!),
                  if (a.location != null && a.location!.isNotEmpty)
                    _detailRow(Icons.location_on_outlined, l10n.receiptLocation, a.location!),
                  _detailRow(Icons.info_outline, l10n.receiptStatus, statusLabel),
                  if (a.amount != null)
                    _detailRow(Icons.payments_outlined, l10n.doctorFees, CurrencyFormatter.format(a.amount!)),
                  if (a.bookingId != null && a.bookingId!.isNotEmpty)
                    _detailRow(Icons.qr_code_2, l10n.receiptBookingId, a.bookingId!.toUpperCase()),
                  if (a.tokenNumber != null && a.tokenNumber! > 0)
                    _detailRow(Icons.confirmation_number_outlined, l10n.receiptToken, '#${a.tokenNumber}'),
                  if (a.isOnlineVisit && isUpcoming) ...[
                    const SizedBox(height: 20),
                    AppButton(
                      label: l10n.doctorVideoConsult,
                      onPressed: () => context.push('/video-consult/${a.id}'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isUpcoming) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: l10n.appointmentsAddToCalendar,
                      variant: AppButtonVariant.secondary,
                      onPressed: () async {
                        final ok = await CalendarHelper.addAppointmentToCalendar(a);
                        if (!context.mounted) return;
                        AppSnackbar.show(
                          context,
                          ok ? l10n.appointmentsCalendarAdded : l10n.appointmentsCalendarFailed,
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
                          await cancelAppointmentAndRefresh(ref, a.id);
                          if (!context.mounted) return;
                          ref.read(appointmentsTabProvider.notifier).state = 2;
                          context.go(RouteNames.appointments);
                          AppSnackbar.show(context, l10n.appointmentsCancelledSuccess, success: true);
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppButton(
                    label: l10n.receiptAppointmentReceipt,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push('/booking/receipt/${a.id}'),
                  ),
                ],
              ),
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
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
