import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/booking_state_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/appointment_receipt_actions.dart';
import '../../utils/appointment_receipt_pdf.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/booking/appointment_receipt_card.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';

/// View receipt later from appointment history (mockup style).
class BookingReceiptScreen extends ConsumerStatefulWidget {
  const BookingReceiptScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends ConsumerState<BookingReceiptScreen> {
  bool _busy = false;

  String _statusFromAppointment(dynamic a) {
    if (a.cancelled) return context.l10n.appointmentsCancelled;
    if (a.isCompleted) return context.l10n.appointmentsCompleted;
    return context.l10n.receiptStatusConfirmed;
  }

  Future<void> _run(Future<void> Function(AppointmentReceiptData) action, AppointmentReceiptData receipt) async {
    final l10n = context.l10n;
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
    final apptAsync = ref.watch(appointmentDetailProvider(widget.appointmentId));
    final patient = ref.watch(patientProfileProvider);

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.receiptAppointmentReceipt,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            onPressed: _busy
                ? null
                : () {
                    final receipt = _buildReceiptData(apptAsync.valueOrNull, draft, patient.valueOrNull);
                    if (receipt != null) {
                      _run((r) => AppointmentReceiptActions.downloadOrSharePdf(r, context.l10n), receipt);
                    }
                  },
          ),
        ],
      ),
      body: patient.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (p) {
          return apptAsync.when(
            loading: () => const AppLoader(),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (appt) {
              final receipt = _buildReceiptData(appt, draft, p);
              if (receipt == null) {
                return _noBookingIdFallback(appt, draft);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: AppointmentReceiptCard(
                  bookingId: receipt.bookingId,
                  tokenNumber: receipt.tokenNumber,
                  patientName: receipt.patientName,
                  doctorName: receipt.doctorName,
                  specialization: receipt.specialization,
                  hospitalName: receipt.hospitalName,
                  location: appt.location ?? draft?.location,
                  roomNo: appt.roomNo ?? draft?.roomNo,
                  appointmentDate: receipt.appointmentDate,
                  appointmentTime: receipt.appointmentTime,
                  visitType: receipt.visitType,
                  status: receipt.status,
                  amountLabel: CurrencyFormatter.format(receipt.amount ?? 0),
                  showConfirmationBanner: true,
                  onWhatsApp: _busy ? null : () => _run(AppointmentReceiptActions.shareWhatsApp, receipt),
                  onEmail: _busy ? null : () => _run(AppointmentReceiptActions.shareEmail, receipt),
                  onPrint: _busy ? null : () => _run((r) => AppointmentReceiptActions.printReceipt(r, context.l10n), receipt),
                ),
              );
            },
          );
        },
      ),
    );
  }

  AppointmentReceiptData? _buildReceiptData(dynamic appt, BookingDraft? draft, dynamic p) {
    final bookingId = appt?.bookingId ?? draft?.bookingId;
    if (bookingId == null || bookingId.isEmpty) return null;

    return AppointmentReceiptData(
      bookingId: bookingId,
      publicId: appt?.publicId ?? draft?.publicId,
      tokenNumber: appt?.tokenNumber ?? draft?.tokenNumber,
      patientName: appt?.patientName ?? draft?.patient.name ?? p?.name ?? context.l10n.receiptPatient,
      doctorName: appt?.doctorName?.isNotEmpty == true ? appt!.doctorName : (draft?.doctor.name ?? ''),
      specialization: appt?.specialization?.isNotEmpty == true
          ? appt!.specialization
          : (draft?.doctor.specialization ?? ''),
      hospitalName: appt?.hospitalName ?? draft?.hospitalName ?? draft?.doctor.hospitalName,
      location: draft?.location ?? appt?.location,
      roomNo: draft?.roomNo ?? appt?.roomNo,
      appointmentDate: DateFormatter.formatSlotDate(
        appt?.slotDate?.isNotEmpty == true ? appt!.slotDate : (draft?.date ?? ''),
      ),
      appointmentTime: appt?.slotTime?.isNotEmpty == true ? appt!.slotTime : (draft?.time ?? ''),
      visitType: draft?.visitType ?? appt?.visitType ?? context.l10n.bookingInClinic,
      status: appt != null ? _statusFromAppointment(appt) : context.l10n.receiptStatusConfirmed,
      amount: appt?.amount ?? draft?.doctor.consultationFee,
    );
  }

  Widget _noBookingIdFallback(dynamic appt, BookingDraft? draft) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.receiptAppointmentReceipt,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.receiptBookingId,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
