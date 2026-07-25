import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../services/queue_service.dart';
import '../../utils/appointment_status_utils.dart';
import '../../utils/theme_context.dart';

enum LiveQueuePanelMode { full, compact }

class LiveQueuePanel extends ConsumerWidget {
  const LiveQueuePanel({
    super.key,
    required this.appointment,
    this.mode = LiveQueuePanelMode.full,
  });

  final AppointmentModel appointment;
  final LiveQueuePanelMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAppointmentToday(appointment.slotDate) ||
        appointment.cancelled ||
        appointment.isCompleted) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final queueAsync = ref.watch(liveQueueProvider(appointment.id));

    return queueAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.logoTeal),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.queueLive,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: context.secondaryText),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status.inactive) return const SizedBox.shrink();
        final lifecycle = (status.lifecycleStatus ?? '').toUpperCase();
        final reception = (status.receptionStatus ?? '').toUpperCase();
        final ready = status.isNextUp ||
            lifecycle == 'CHECKED_IN' ||
            lifecycle == 'IN_PROGRESS' ||
            reception == 'READY_FOR_DOCTOR' ||
            appointmentShowsLiveQueue(appointment);
        if (!ready) return const SizedBox.shrink();
        return mode == LiveQueuePanelMode.compact
            ? _CompactQueueRow(status: status)
            : _FullQueuePanel(status: status);
      },
    );
  }
}

class _CompactQueueRow extends StatelessWidget {
  const _CompactQueueRow({required this.status});

  final LiveQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final token = status.tokenNumber;
    if (token == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.confirmation_number_outlined,
              size: 14, color: AppColors.logoTeal),
          const SizedBox(width: 6),
          Text(
            '${l10n.queueYourToken} #$token',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.logoTeal),
          ),
          if (status.currentlyServingToken != null) ...[
            const SizedBox(width: 8),
            Text(
              '· ${l10n.queueNowServing} #${status.currentlyServingToken}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: context.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullQueuePanel extends StatelessWidget {
  const _FullQueuePanel({required this.status});

  final LiveQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final token = status.tokenNumber;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.logoTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.logoTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.queue_play_next_rounded,
                  size: 18, color: AppColors.logoTeal),
              const SizedBox(width: 8),
              Text(
                l10n.queueLive,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText),
              ),
              const Spacer(),
              if (status.queuePosition > 0)
                Text(
                  '${l10n.queuePosition}: ${status.queuePosition}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: context.secondaryText),
                ),
            ],
          ),
          if (status.isNextUp) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.queueYourTurnNext,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
          if (token != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    l10n.queueYourToken,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: context.secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$token',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.logoTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status.currentlyServingToken != null ||
              status.patientsAhead > 0) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (status.currentlyServingToken != null)
                  '${l10n.queueNowServing} #${status.currentlyServingToken}',
                if (status.patientsAhead > 0)
                  l10n.queuePatientsAhead(status.patientsAhead),
              ].join(' · '),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: context.secondaryText),
            ),
          ],
          if (status.queueTokens.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: status.queueTokens.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final t = status.queueTokens[i];
                  final isMine = t == token;
                  final isServing = t == status.currentlyServingToken;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isServing
                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                          : isMine
                              ? AppColors.logoTeal.withValues(alpha: 0.15)
                              : context.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMine || isServing
                            ? (isServing
                                ? AppColors.primaryBlue
                                : AppColors.logoTeal)
                            : context.borderColor,
                      ),
                    ),
                    child: Text(
                      '#$t',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isMine || isServing
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isServing
                            ? AppColors.primaryBlue
                            : isMine
                                ? AppColors.logoTeal
                                : context.secondaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
