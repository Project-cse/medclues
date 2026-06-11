import 'dart:async';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_booking_info.dart';
import '../../models/slot_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_state_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/app_permissions_service.dart';
import '../../services/payment_service.dart';
import '../../services/razorpay_checkout_service.dart';
import '../../routes/route_names.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/specialization_symptoms.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/booking/premium_booking_theme.dart';
import '../../widgets/booking/premium_booking_widgets.dart';
import '../../widgets/booking/premium_date_chip.dart';
import '../../widgets/booking/premium_opd_slot_chip.dart';
import 'package:url_launcher/url_launcher.dart';

/// Matches mobile/app/book-appointment.tsx
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.doctorId, this.preferOnline = false});

  final String doctorId;
  final bool preferOnline;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _dayIndex = 0;
  SlotModel? _selectedSlot;
  /// Pay in advance via Razorpay on the in-clinic booking flow (not video consult).
  bool _payOnline = false;
  bool _booking = false;
  final _note = TextEditingController();
  final _dateScroll = ScrollController();
  final Set<String> _selectedSymptoms = {};
  PlatformFile? _reportFile;
  String? _reportFileName;
  late final List<({String label, int dayNum, String slotDate, String monthShort})> _week;
  Timer? _slotRefreshTimer;

  PatientBookingInfo get _patient =>
      ref.read(bookingPatientProvider) ?? PatientBookingInfo(name: 'Patient', isSelf: true);

  Future<void> _completeBooking({
    required DoctorModel doctor,
    required String selectedDate,
    required String slotTime,
    required Map<String, dynamic> result,
    required String visitType,
    required String paymentMethod,
  }) async {
    final apptId = result['appointmentId']?.toString() ?? '';
    final token = result['tokenNumber'] is num
        ? (result['tokenNumber'] as num).toInt()
        : int.tryParse('${result['tokenNumber'] ?? ''}');
    final queue = result['queuePosition'] is num
        ? (result['queuePosition'] as num).toInt()
        : int.tryParse('${result['queuePosition'] ?? ''}');
    final bookingId = result['bookingId']?.toString() ?? result['booking_id']?.toString();

    ref.read(bookingDraftProvider.notifier).state = BookingDraft(
      doctor: doctor,
      date: selectedDate,
      time: slotTime,
      visitType: visitType,
      notes: _note.text,
      appointmentId: apptId,
      bookingId: bookingId,
      tokenNumber: token,
      queuePosition: queue,
      patient: _patient,
      hospitalName: doctor.hospitalName,
      location: doctor.addressLine1 ?? doctor.address,
      roomNo: doctor.addressLine2,
    );
    ref.invalidate(upcomingAppointmentsProvider);
    ref.invalidate(doctorScheduleProvider((doctorId: widget.doctorId, mode: _slotMode)));
    if (mounted) context.go(RouteNames.bookingSuccess);
  }

  void _invalidateSchedule() {
    ref.invalidate(doctorScheduleProvider((doctorId: widget.doctorId, mode: _slotMode)));
  }

  Widget _buildOpdSlotChip(SlotModel slot) {
    final l10n = context.l10n;
    return PremiumOpdSlotChip(
      label: DateFormatter.displayTime(slot.displayTime),
      selected: _selectedSlot?.time == slot.time,
      enabled: slot.available,
      remainingCount: slot.availableCount,
      remainingLabel: slot.availableCount != null
          ? l10n.bookingAppointmentsLeft(slot.availableCount!)
          : null,
      fullLabel: l10n.bookingSlotFull,
      onTap: slot.available ? () => setState(() => _selectedSlot = slot) : null,
    );
  }

  Future<void> _pickReport() async {
    final ok = await AppPermissionsService.ensurePhotos();
    if (!ok && mounted) {
      AppSnackbar.show(context, context.l10n.permissionsFiles);
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (picked != null && picked.files.isNotEmpty) {
      setState(() {
        _reportFile = picked.files.first;
        _reportFileName = picked.files.first.name;
      });
    }
  }

  /// Slot API mode: online = video consult slots; offline = OPD blocks.
  String get _slotMode => widget.preferOnline ? 'online' : 'offline';

  bool get _requiresRazorpay => widget.preferOnline || _payOnline;

  Future<Map<String, dynamic>> _collectRazorpayPayment({
    required PaymentService paymentService,
    required PaymentOrderResult order,
    required DoctorModel doctor,
  }) async {
    final useNativeCheckout = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (useNativeCheckout) {
      final user = ref.read(authProvider).user;
      final checkout = RazorpayCheckoutService();
      try {
        final payment = await checkout.openCheckout(
          key: order.razorpayKey,
          orderId: order.orderId,
          amountPaise: order.amount,
          description: context.l10n.bookingConsultationWith(doctor.name),
          customerName: user?.name,
          customerEmail: user?.email,
          customerPhone: user?.phone ?? _patient.phone,
        );
        return paymentService.verifyAppointmentPayment(
          orderId: payment.orderId,
          paymentId: payment.paymentId,
          signature: payment.signature,
          appointmentId: order.appointmentId,
        );
      } finally {
        checkout.dispose();
      }
    }

    final checkoutUrl = paymentService.checkoutUrl(order.checkoutToken);
    final launched = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception(context.l10n.paymentCouldNotOpen);
    }
    return _waitForPaymentCompletion(order);
  }

  Future<void> _submitBooking(DoctorModel doctor) async {
    if (_selectedSlot == null) {
      AppSnackbar.show(context, context.l10n.bookingSelectDateTime);
      return;
    }

    final availableSymptoms = SpecializationSymptoms.forSpecialization(doctor.specialization);
    if (availableSymptoms.isNotEmpty && _selectedSymptoms.isEmpty) {
      AppSnackbar.show(context, context.l10n.bookingSelectSymptom);
      return;
    }

    // Snapshot slot before any await — schedule refresh can clear _selectedSlot mid-flow.
    final slot = _selectedSlot!;
    final slotTime = slot.time;
    final slotId = slot.slotId;
    final slotType = inferOpdSlotType(slot.displayTime, slot.slotType);

    setState(() => _booking = true);
    final selectedDate = _week[_dayIndex].slotDate;
    final notes = _note.text.trim().isEmpty ? null : _note.text.trim();
    final symptoms = _selectedSymptoms.toList();

    try {
      if (_requiresRazorpay) {
        if (!_patient.isSelf) {
          AppSnackbar.show(
            context,
            context.l10n.bookingOnlineOthersPayment,
          );
          return;
        }
        final paymentService = ref.read(paymentServiceProvider);
        final isVideo = widget.preferOnline;
        final fee = isVideo ? doctor.videoConsultationFee : doctor.consultationFee;
        final feePaise = (fee * 100).round();
        final order = await paymentService.createAppointmentOrder(
          amountPaise: feePaise,
          doctorId: widget.doctorId,
          appointmentDate: selectedDate,
          appointmentTime: slotTime,
          notes: notes,
          slotId: slotId,
          slotType: slotType,
          mode: isVideo ? 'online' : 'offline',
          visitType: isVideo ? 'Online' : 'In-clinic',
        );
        if (!mounted) return;

        Map<String, dynamic> payResult;
        try {
          payResult = await _collectRazorpayPayment(
            paymentService: paymentService,
            order: order,
            doctor: doctor,
          );
        } catch (e) {
          await paymentService.recordFailedPayment(
            orderId: order.orderId,
            appointmentId: order.appointmentId,
            error: e.toString(),
          );
          rethrow;
        }
        final enriched = <String, dynamic>{
          'appointmentId': payResult['appointment_id']?.toString() ?? '',
          'bookingId': payResult['bookingId'] ?? payResult['booking_id'],
          'tokenNumber': payResult['tokenNumber'],
        };
        await _completeBooking(
          doctor: doctor,
          selectedDate: selectedDate,
          slotTime: slotTime,
          result: enriched,
          visitType: isVideo ? 'Online' : 'In-clinic',
          paymentMethod: 'onlinePayment',
        );
        return;
      }

      final result = await ref.read(appointmentRepositoryProvider).book(
            doctorId: widget.doctorId,
            slotDate: selectedDate,
            slotTime: slotTime,
            symptoms: symptoms,
            notes: notes,
            hospitalName: doctor.hospitalName,
            location: doctor.address,
            patient: _patient,
            paymentMethod: 'payOnVisit',
            visitType: 'In-clinic',
            mode: 'offline',
            slotId: slotId,
            slotType: slotType,
            prescription: _reportFile,
          );
      await _completeBooking(
        doctor: doctor,
        selectedDate: selectedDate,
        slotTime: slotTime,
        result: result,
        visitType: 'In-clinic',
        paymentMethod: 'payOnVisit',
      );
    } catch (e) {
      _invalidateSchedule();
      if (mounted) {
        AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Future<Map<String, dynamic>> _tryConfirmPaidOrder(
    PaymentService paymentService,
    String orderId,
  ) async {
    final status = await paymentService.getOrderStatus(orderId);
    if (status['failed'] == true) {
      throw Exception(context.l10n.paymentFailed);
    }
    if (status['paid'] == true) {
      return paymentService.confirmPaidOrder(orderId);
    }
    throw Exception(context.l10n.paymentNotCompleted);
  }

  Future<Map<String, dynamic>> _waitForPaymentCompletion(PaymentOrderResult order) async {
    final paymentService = ref.read(paymentServiceProvider);
    final l10n = context.l10n;
    final cancelCompleter = Completer<void>();
    final confirmNowCompleter = Completer<void>();
    var statusLabel = l10n.paymentCompleteBrowserHint;
    var dialogOpen = false;
    void Function(void Function())? dialogSetState;

    if (mounted) {
      dialogOpen = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                dialogSetState = setDialogState;
                return AlertDialog(
                  title: Text(l10n.paymentWaitingTitle),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )),
                      Text(statusLabel),
                      const SizedBox(height: 12),
                      Text(l10n.paymentOrderLabel(order.orderId), style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        l10n.paymentTapIvePaidHint,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (!cancelCompleter.isCompleted) cancelCompleter.complete();
                        Navigator.pop(ctx);
                      },
                      child: Text(l10n.commonCancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (!confirmNowCompleter.isCompleted) confirmNowCompleter.complete();
                      },
                      child: Text(l10n.paymentIvePaid),
                    ),
                  ],
                );
              },
            ),
          ),
        ).whenComplete(() => dialogOpen = false),
      );
    }

    try {
      final deadline = DateTime.now().add(const Duration(minutes: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (cancelCompleter.isCompleted) {
          throw Exception(l10n.paymentCancelled);
        }
        if (!mounted) throw Exception(l10n.paymentCancelled);

        await Future.any<void>([
          Future<void>.delayed(const Duration(seconds: 2)),
          cancelCompleter.future,
          confirmNowCompleter.future,
        ]);
        if (cancelCompleter.isCompleted) {
          throw Exception(l10n.paymentCancelled);
        }

        try {
          final result = await _tryConfirmPaidOrder(paymentService, order.orderId);
          return result;
        } catch (e) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          if (msg.contains('Payment failed') || msg.contains('Payment cancelled')) {
            rethrow;
          }
          statusLabel = msg.contains('not completed')
              ? l10n.paymentFinishThenTap
              : l10n.paymentConfirmingBooking(msg);
          dialogSetState?.call(() {});
        }
      }

      if (cancelCompleter.isCompleted) {
        throw Exception(l10n.paymentCancelled);
      }

      final manual = await _showPaymentVerifyDialog(order, statusLabel);
      if (manual == null) {
        throw Exception(l10n.paymentCancelled);
      }
      return paymentService.verifyAppointmentPayment(
        orderId: manual.$1,
        paymentId: manual.$2,
        signature: manual.$3,
        appointmentId: order.appointmentId,
      );
    } finally {
      if (mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<(String, String, String)?> _showPaymentVerifyDialog(
    PaymentOrderResult order, [
    String? statusHint,
  ]) async {
    final paymentId = TextEditingController();
    final signature = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.paymentCompleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusHint != null
                  ? context.l10n.paymentCompleteAutoHint(statusHint)
                  : context.l10n.paymentCompleteBrowserHint,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.paymentOrderLabel(order.orderId), style: const TextStyle(fontSize: 12)),
            TextField(controller: paymentId, decoration: InputDecoration(labelText: context.l10n.paymentPaymentId)),
            TextField(controller: signature, decoration: InputDecoration(labelText: context.l10n.paymentSignature)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.paymentVerify)),
        ],
      ),
    );
    if (result != true || paymentId.text.isEmpty || signature.text.isEmpty) return null;
    return (order.orderId, paymentId.text.trim(), signature.text.trim());
  }

  String get _patientSelectorPath {
    final q = widget.preferOnline ? '?visit=online' : '';
    return '/booking/patient/${widget.doctorId}$q';
  }

  @override
  void initState() {
    super.initState();
    _week = DateFormatter.buildNext5Days();
    _payOnline = false;
    final slotMode = widget.preferOnline ? 'online' : 'offline';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      prefetchDoctorSchedule(ref, widget.doctorId, mode: slotMode);
      _invalidateSchedule();
      if (ref.read(bookingPatientProvider) == null) {
        context.replace(_patientSelectorPath);
      }
    });
    _slotRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _invalidateSchedule();
    });
  }

  void _selectDay(int index) {
    if (index < 0 || index >= _week.length) return;
    setState(() {
      _dayIndex = index;
      _selectedSlot = null;
    });
    if (_dateScroll.hasClients) {
      final offset = (index * 82.0).clamp(0.0, _dateScroll.position.maxScrollExtent);
      _dateScroll.animateTo(offset, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  void _advanceDate() {
    if (_dayIndex < _week.length - 1) _selectDay(_dayIndex + 1);
  }

  Future<void> _openCalendarPicker() async {
    final today = DateTime.now();
    final last = today.add(Duration(days: _week.length - 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(Duration(days: _dayIndex)),
      firstDate: today,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: PremiumBookingTheme.primaryBlue,
            onPrimary: Colors.white,
            surface: PremiumBookingTheme.white(context),
            onSurface: PremiumBookingTheme.text(context),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    final idx = _week.indexWhere(
      (d) => d.dayNum == picked.day && d.monthShort == DateFormat('MMM').format(picked),
    );
    if (idx >= 0) _selectDay(idx);
  }

  @override
  void dispose() {
    _slotRefreshTimer?.cancel();
    _note.dispose();
    _dateScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final selectedDate = _week[_dayIndex].slotDate;
    final slotMode = _slotMode;
    final scheduleAsync = ref.watch(
      doctorScheduleProvider((doctorId: widget.doctorId, mode: slotMode)),
    );

    final pageTitle = widget.preferOnline ? l10n.bookingBookVideoConsult : l10n.bookingBookAppointment;

    return Scaffold(
      backgroundColor: PremiumBookingTheme.background(context),
      appBar: PremiumBookingAppBar(title: pageTitle),
      body: doctorAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (doctor) {
          final fee = widget.preferOnline ? doctor.videoConsultationFee : doctor.consultationFee;
          final canBook = _selectedSlot != null;
          final symptoms = SpecializationSymptoms.forSpecialization(doctor.specialization);
          final ctaLabel = _booking
              ? l10n.bookingConfirming
              : _requiresRazorpay
                  ? l10n.bookingPayAndBook(CurrencyFormatter.format(fee))
                  : l10n.bookingBookAppointment;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    PremiumBookingTheme.horizontalPadding,
                    8,
                    PremiumBookingTheme.horizontalPadding,
                    24,
                  ),
                  children: [
                    PremiumDoctorBookingCard(doctor: doctor),
                    const SizedBox(height: PremiumBookingTheme.sectionGap),
                    PremiumBookingSectionHeader(
                      title: l10n.bookingSelectDate,
                      trailing: PremiumViewCalendarAction(onTap: _openCalendarPicker),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 108,
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              controller: _dateScroll,
                              scrollDirection: Axis.horizontal,
                              itemCount: _week.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final d = _week[i];
                                return PremiumDateChip(
                                  weekdayLabel: d.label,
                                  dayNum: d.dayNum,
                                  monthShort: d.monthShort,
                                  selected: i == _dayIndex,
                                  onTap: () => _selectDay(i),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          PremiumDateNavButton(onTap: _advanceDate),
                        ],
                      ),
                    ),
                    const SizedBox(height: PremiumBookingTheme.sectionGap),
                    PremiumBookingSectionHeader(
                      title: widget.preferOnline ? l10n.bookingVideoSlots : l10n.bookingOpdSlots,
                      icon: Icons.schedule_rounded,
                    ),
                    const SizedBox(height: 14),
                    scheduleAsync.when(
                      skipLoadingOnReload: true,
                      data: (schedule) {
                        final day = schedule[selectedDate];
                        final slots = day?.slots ?? const <SlotModel>[];
                        final selectedStillValid = _selectedSlot == null ||
                            slots.any(
                              (s) => s.time == _selectedSlot!.time && s.available,
                            );
                        if (!selectedStillValid && _selectedSlot != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selectedSlot = null);
                          });
                        }
                        if (slots.isEmpty) {
                          return Text(
                            l10n.bookingNoSlots,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: PremiumBookingTheme.textSecondary(context),
                            ),
                          );
                        }
                        if (slots.length == 2) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < slots.length; i++) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(child: _buildOpdSlotChip(slots[i])),
                              ],
                            ],
                          );
                        }
                        return Column(
                          children: [
                            for (final s in slots) ...[
                              _buildOpdSlotChip(s),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: PremiumBookingTheme.primaryBlue),
                        ),
                      ),
                      error: (e, _) => Text(
                        '$e',
                        style: GoogleFonts.inter(color: PremiumBookingTheme.textSecondary(context)),
                      ),
                    ),
                    if (symptoms.isNotEmpty) ...[
                      const SizedBox(height: PremiumBookingTheme.sectionGap),
                      PremiumSymptomsCard(
                        specialization: doctor.specialization,
                        symptoms: symptoms,
                        selected: _selectedSymptoms,
                        onToggle: (s) => setState(() {
                          if (_selectedSymptoms.contains(s)) {
                            _selectedSymptoms.remove(s);
                          } else {
                            _selectedSymptoms.add(s);
                          }
                        }),
                      ),
                    ],
                    const SizedBox(height: PremiumBookingTheme.sectionGap),
                    _reportsCard(doctor),
                    if (!widget.preferOnline) ...[
                      const SizedBox(height: PremiumBookingTheme.sectionGap),
                      _sectionTitle(l10n.bookingPaymentMode),
                      Row(
                        children: [
                          Expanded(
                            child: _visitPill(
                              label: l10n.bookingInClinic,
                              active: !_payOnline,
                              onTap: () => setState(() => _payOnline = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _visitPill(
                              label: l10n.bookingPayOnline,
                              active: _payOnline,
                              onTap: () => setState(() => _payOnline = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_payOnline)
                        _infoBanner(
                          icon: Icons.payment_rounded,
                          text:
                              l10n.bookingPayOnlineBanner(CurrencyFormatter.format(doctor.consultationFee)),
                        )
                      else
                        Text(
                          l10n.bookingInClinicPayHint,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: PremiumBookingTheme.textSecondary(context),
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.bookingVideoFeeRequired(CurrencyFormatter.format(fee)),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PremiumBookingTheme.textSecondary(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: PremiumBookingTheme.sectionGap),
                    _sectionTitle(l10n.bookingAdditionalNotes),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 14, color: PremiumBookingTheme.text(context)),
                      decoration: InputDecoration(
                        hintText: l10n.bookingAdditionalNotes,
                        hintStyle: GoogleFonts.inter(color: PremiumBookingTheme.textSecondary(context)),
                        filled: true,
                        fillColor: PremiumBookingTheme.white(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: PremiumBookingTheme.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: PremiumBookingTheme.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PremiumBookingTheme.accentBlue, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: PremiumBookingTheme.sectionGap),
                    const PremiumSecurityCard(),
                  ],
                ),
              ),
              PremiumBookAppointmentCta(
                label: ctaLabel,
                enabled: canBook,
                loading: _booking,
                onPressed: canBook && !_booking ? () => _submitBooking(doctor) : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: PremiumBookingTheme.sectionTitleStyle(context)),
        const SizedBox(height: 10),
        Divider(height: 1, color: PremiumBookingTheme.border(context)),
      ],
    );
  }

  Widget _infoBanner({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PremiumBookingTheme.securityBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumBookingTheme.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: PremiumBookingTheme.iconBadge(context),
            child: Icon(icon, color: PremiumBookingTheme.accentBlue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: PremiumBookingTheme.sectionSubtitleStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportsCard(DoctorModel doctor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PremiumBookingTheme.corporateCard(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: PremiumBookingTheme.iconBadge(context),
            child: const Icon(Icons.description_outlined, size: 18, color: PremiumBookingTheme.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.bookingUploadReport,
                  style: PremiumBookingTheme.sectionTitleStyle(context),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.bookingPickReport,
                  style: PremiumBookingTheme.sectionSubtitleStyle(context),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: PremiumBookingTheme.border(context)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickReport,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: Text(
                    _reportFileName ?? context.l10n.bookingUploadReport,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PremiumBookingTheme.accentBlue,
                    backgroundColor: PremiumBookingTheme.chipSelectedBg(context),
                    side: BorderSide(
                      color: PremiumBookingTheme.accentBlue.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_reportFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _reportFileName!,
                      style: GoogleFonts.inter(fontSize: 11, color: PremiumBookingTheme.accentBlue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? PremiumBookingTheme.selectedGradient : null,
          color: active ? null : PremiumBookingTheme.white(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? PremiumBookingTheme.primaryBlue : PremiumBookingTheme.border(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: active ? Colors.white : PremiumBookingTheme.text(context),
          ),
        ),
      ),
    );
  }
}
