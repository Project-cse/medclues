import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';

class ConsultationPrescriptionDetailScreen extends ConsumerWidget {
  const ConsultationPrescriptionDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(consultationSummaryProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordsPrescriptionDetail, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          if (summary case AsyncData(:final value) when value != null && value.hasContent)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: () {
                final text = [
                  if (value.diagnosis?.trim().isNotEmpty ?? false) '${l10n.recordsDiagnosis}: ${value.diagnosis}',
                  if (value.prescription?.trim().isNotEmpty ?? false) '${l10n.recordsTypePrescription}: ${value.prescription}',
                  if (value.advice?.trim().isNotEmpty ?? false) '${l10n.recordsAdvice}: ${value.advice}',
                ].join('\n\n');
                Clipboard.setData(ClipboardData(text: text));
                AppSnackbar.show(context, 'Copied to clipboard', success: true);
              },
            ),
        ],
      ),
      body: summary.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (s) {
          if (s == null || !s.hasContent) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.recordsNoPrescriptionYet,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final tablets = _extractTablets(s.attachments);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (s.diagnosis?.trim().isNotEmpty ?? false)
                _section(l10n.recordsDiagnosis, s.diagnosis!),
              if (tablets.isNotEmpty) _tabletsSection(l10n.recordsTablets, tablets),
              if (s.prescription?.trim().isNotEmpty ?? false)
                _section(l10n.recordsTypePrescription, s.prescription!),
              if (s.advice?.trim().isNotEmpty ?? false) _section(l10n.recordsAdvice, s.advice!),
              if (s.followupDate?.trim().isNotEmpty ?? false)
                _section(l10n.recordsFollowUp, s.followupDate!),
              if (s.notes?.trim().isNotEmpty ?? false) _section('Notes', s.notes!),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _extractTablets(List<dynamic> attachments) {
    for (final a in attachments) {
      if (a is Map && a['tablets'] is List) {
        return (a['tablets'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  Widget _section(String title, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _tabletsSection(String title, List<Map<String, dynamic>> tablets) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ...tablets.map<Widget>((t) {
            final name = t['name']?.toString() ?? t['tablet']?.toString() ?? 'Medicine';
            final dose = t['dosage']?.toString() ?? t['dose']?.toString() ?? '';
            final duration = t['duration']?.toString() ?? '';
            final instructions = t['instructions']?.toString() ?? t['frequency']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medication_liquid_outlined, size: 18, color: AppColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if ([dose, duration, instructions].any((s) => s.isNotEmpty))
                          Text(
                            [dose, duration, instructions].where((s) => s.isNotEmpty).join(' · '),
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
