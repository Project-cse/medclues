import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/common/app_button.dart';

class ConsultationSummaryScreen extends ConsumerWidget {
  const ConsultationSummaryScreen({
    super.key,
    required this.appointmentId,
    this.durationSeconds = 0,
    this.message,
  });

  final String appointmentId;
  final int durationSeconds;
  final String? message;

  String _durationLabel() {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appt = ref.watch(appointmentDetailProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Consultation summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      body: appt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (a) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, color: AppColors.logoTeal, size: 72),
              const SizedBox(height: 16),
              Text(
                l10n.videoEndCall,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Your video consultation has ended.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              _row(Icons.person_outline, 'Doctor', a.doctorName),
              _row(Icons.schedule, 'Duration', _durationLabel()),
              _row(Icons.calendar_today_outlined, 'Date', '${a.slotDate} · ${a.slotTime}'),
              const Spacer(),
              AppButton(
                label: l10n.commonDone,
                onPressed: () => context.go(RouteNames.appointments),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.logoTeal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
