import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/booking_state_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/appointment_receipt_actions.dart';
import '../../utils/appointment_receipt_pdf.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/animations/receipt_unroll.dart';
import '../../widgets/booking/appointment_receipt_card.dart';
import '../../widgets/common/app_snackbar.dart';

/// Post-booking receipt screen (mockup style).
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  bool _busy = false;

  AppointmentReceiptData? _receiptData(BookingDraft draft) {
    final id = draft.bookingId;
    if (id == null || id.isEmpty) return null;
    return AppointmentReceiptData(
      bookingId: id,
      tokenNumber: draft.tokenNumber,
      patientName: draft.patient.name,
      doctorName: draft.doctor.name,
      specialization: draft.doctor.specialization,
      hospitalName: draft.hospitalName ?? draft.doctor.hospitalName,
      location: draft.location,
      roomNo: draft.roomNo,
      appointmentDate: DateFormatter.formatSlotDate(draft.date),
      appointmentTime: draft.time,
      visitType: draft.visitType,
      status: context.l10n.receiptStatusConfirmed,
      amount: draft.doctor.consultationFee,
    );
  }

  Future<void> _runReceiptAction(Future<void> Function(AppointmentReceiptData) action) async {
    final l10n = context.l10n;
    final draft = ref.read(bookingDraftProvider);
    final receipt = draft == null ? null : _receiptData(draft);
    if (receipt == null) {
      AppSnackbar.show(context, l10n.receiptBookingId);
      return;
    }
    setState(() => _busy = true);
    try {
      await action(receipt);
      if (mounted) AppSnackbar.show(context, l10n.commonDone, success: true);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, l10n.commonError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = ref.watch(bookingDraftProvider);
    if (draft == null) {
      return Scaffold(
          body: Center(
          child: TextButton(onPressed: () => context.go(RouteNames.dashboard), child: Text(l10n.navHome)),
        ),
      );
    }

    final hasBookingId = draft.bookingId != null && draft.bookingId!.isNotEmpty;
    final isOnline = draft.visitType.toLowerCase().contains('online');
    final apptId = draft.appointmentId ?? '';

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text(
          l10n.receiptAppointmentReceipt,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          if (hasBookingId)
            IconButton(
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              onPressed: _busy
                  ? null
                  : () => _runReceiptAction(
                        (r) => AppointmentReceiptActions.downloadOrSharePdf(r, context.l10n),
                      ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            ReceiptUnroll(
              child: AppointmentReceiptCard(
              bookingId: draft.bookingId,
              tokenNumber: draft.tokenNumber,
              patientName: draft.patient.name,
              doctorName: draft.doctor.name,
              specialization: draft.doctor.specialization,
              hospitalName: draft.hospitalName ?? draft.doctor.hospitalName,
              location: draft.location,
              roomNo: draft.roomNo,
              appointmentDate: DateFormatter.formatSlotDate(draft.date),
              appointmentTime: draft.time,
              visitType: draft.visitType,
              status: l10n.receiptStatusConfirmed,
              amountLabel: CurrencyFormatter.format(draft.doctor.consultationFee),
              showConfirmationBanner: true,
              onWhatsApp: hasBookingId && !_busy
                  ? () => _runReceiptAction(AppointmentReceiptActions.shareWhatsApp)
                  : null,
              onEmail: hasBookingId && !_busy
                  ? () => _runReceiptAction(AppointmentReceiptActions.shareEmail)
                  : null,
              onPrint: hasBookingId && !_busy
                  ? () => _runReceiptAction(
                        (r) => AppointmentReceiptActions.printReceipt(r, context.l10n),
                      )
                  : null,
            ),
            ),
            if (!hasBookingId)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.receiptBookingId,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            if (isOnline && apptId.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/video-waiting/$apptId'),
                  icon: const Icon(Icons.videocam),
                  label: Text(l10n.doctorVideoConsult, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.specCircleFill,
                    foregroundColor: AppColors.brandNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(RouteNames.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l10n.navHome, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.appointments),
              child: Text(
                l10n.appointmentsTitle,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.logoTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
