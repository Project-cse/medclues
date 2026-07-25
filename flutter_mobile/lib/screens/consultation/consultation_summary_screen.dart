import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../routes/route_names.dart';
import '../../services/consultation_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_loader.dart';

class ConsultationSummaryScreen extends ConsumerStatefulWidget {
  const ConsultationSummaryScreen({
    super.key,
    required this.appointmentId,
    this.durationSeconds = 0,
    this.message,
  });

  final String appointmentId;
  final int durationSeconds;
  final String? message;

  @override
  ConsumerState<ConsultationSummaryScreen> createState() => _ConsultationSummaryScreenState();
}

class _ConsultationSummaryScreenState extends ConsumerState<ConsultationSummaryScreen> {
  Timer? _pollTimer;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSummary();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_pollCount >= 10) {
          _pollTimer?.cancel();
          return;
        }
        _pollCount++;
        _refreshSummary();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _refreshSummary() {
    ref.invalidate(consultationSummaryProvider(widget.appointmentId));
    ref.invalidate(appointmentDetailProvider(widget.appointmentId));
  }

  String _durationLabel() {
    final m = widget.durationSeconds ~/ 60;
    final s = widget.durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appt = ref.watch(appointmentDetailProvider(widget.appointmentId));
    final summary = ref.watch(consultationSummaryProvider(widget.appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Consultation summary',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshSummary,
            tooltip: 'Refresh prescription',
          ),
        ],
      ),
      body: appt.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (a) => summary.when(
          loading: () => const AppLoader(),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (s) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _endedBanner(l10n.videoEndCall, widget.message),
                      const SizedBox(height: 16),
                      _visitDetailsCard(
                        doctorName: a.doctorName,
                        duration: _durationLabel(),
                        dateLine: '${a.slotDate} · ${a.slotTime}',
                      ),
                      const SizedBox(height: 16),
                      if (s != null && s.hasContent)
                        _clinicalNotesSection(s)
                      else
                        _waitingForPrescriptionCard(),
                    ],
                  ),
                ),
              ),
              _bottomActions(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _endedBanner(String title, String? message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.medcluesTeal.withValues(alpha: 0.15),
                  AppColors.logoTeal.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.medcluesTeal, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'Your video consultation has ended.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitDetailsCard({
    required String doctorName,
    required String duration,
    required String dateLine,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _metaRow(Icons.person_outline_rounded, 'Doctor', doctorName),
          const Divider(height: 24, color: AppColors.divider),
          _metaRow(Icons.schedule_rounded, 'Duration', duration),
          const Divider(height: 24, color: AppColors.divider),
          _metaRow(Icons.calendar_today_outlined, 'Date', dateLine),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandBlueLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.brandBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _clinicalNotesSection(ConsultationSummary summary) {
    final hasPrescription =
        summary.prescription != null && summary.prescription!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_outlined, color: AppColors.medcluesTeal, size: 22),
            const SizedBox(width: 8),
            Text(
              'Prescription & notes',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (hasPrescription) ...[
          _prescriptionHeroCard(summary.prescription!.trim()),
          const SizedBox(height: 12),
        ],
        if (summary.diagnosis != null && summary.diagnosis!.trim().isNotEmpty)
          _clinicalNoteCard(
            icon: Icons.medical_information_outlined,
            title: 'Diagnosis',
            body: summary.diagnosis!.trim(),
            accent: AppColors.brandBlue,
          ),
        if (summary.notes != null && summary.notes!.trim().isNotEmpty)
          _clinicalNoteCard(
            icon: Icons.notes_rounded,
            title: 'Clinical notes',
            body: summary.notes!.trim(),
            accent: AppColors.textGray700,
          ),
        if (summary.advice != null && summary.advice!.trim().isNotEmpty)
          _clinicalNoteCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Advice',
            body: summary.advice!.trim(),
            accent: AppColors.success,
          ),
        if (summary.followupDate != null && summary.followupDate!.trim().isNotEmpty)
          _followUpCard(summary.followupDate!.trim()),
      ],
    );
  }

  Widget _prescriptionHeroCard(String prescription) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.medcluesTeal.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.medcluesTeal.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.medcluesTeal.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_liquid_rounded, color: AppColors.medcluesTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your prescription',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.medcluesNavy,
                        ),
                      ),
                      Text(
                        'Issued by your doctor',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              prescription,
              style: GoogleFonts.sourceSans3(
                fontSize: 15,
                height: 1.65,
                letterSpacing: 0.15,
                color: AppColors.textGray800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicalNoteCard({
    required IconData icon,
    required String title,
    required String body,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textGray800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _followUpCard(String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlueLight,
            AppColors.secondaryLight,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: AppColors.brandBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow-up visit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingForPrescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for prescription',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your doctor may still be writing your prescription. This page refreshes automatically.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.45,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(dynamic l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'View appointment',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push('/appointments/${widget.appointmentId}'),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: l10n.commonDone,
            onPressed: () => context.go(RouteNames.appointments),
          ),
        ],
      ),
    );
  }
}
