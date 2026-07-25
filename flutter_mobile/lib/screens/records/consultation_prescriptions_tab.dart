import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/consultation_list_item.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/theme_context.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loader.dart';

class ConsultationPrescriptionsTab extends ConsumerWidget {
  const ConsultationPrescriptionsTab({super.key});

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      if (raw.isEmpty || raw == 'null') return '';
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final consultations = ref.watch(userConsultationsProvider);

    return consultations.when(
      loading: () => const AppLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: context.secondaryText),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(userConsultationsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.logoTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return AppEmptyState(
            title: l10n.recordsPrescriptionsEmpty,
            subtitle: l10n.recordsPrescriptionsEmptyHint,
          );
        }
        return RefreshIndicator(
          color: AppColors.logoTeal,
          onRefresh: () async {
            ref.invalidate(userConsultationsProvider);
            await ref.read(userConsultationsProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = list[i];
              return _PrescriptionCard(
                item: item,
                dateLabel: _formatDate(item.date),
                onTap: () {
                  final id = item.appointmentId.trim();
                  if (id.isNotEmpty && id != 'null') {
                    context.push('/records/prescription/$id');
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.item,
    required this.dateLabel,
    required this.onTap,
  });

  final ConsultationListItem item;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_outlined, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.doctorName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                      ),
                    ),
                    if (item.speciality.isNotEmpty)
                      Text(
                        item.speciality,
                        style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                      ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: GoogleFonts.poppins(fontSize: 11, color: context.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.hasPrescription)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Rx',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: context.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
