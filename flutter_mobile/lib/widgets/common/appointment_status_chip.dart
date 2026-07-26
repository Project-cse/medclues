import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/l10n_extension.dart';
import '../../models/appointment_model.dart';
import '../../utils/appointment_status_utils.dart';
import '../../utils/theme_context.dart';

/// Shared lifecycle → display label map (parity with admin lifecycleLabels).
String appointmentStatusLabelFor(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'cancelled' => l10n.statusCancelled,
    'completed' => l10n.statusCompleted,
    'doctorOnBreak' => l10n.statusDoctorOnBreak,
    'inProgress' => l10n.statusInProgress,
    'inConsultation' => l10n.statusInConsultation,
    'nextToConsult' => l10n.statusNextToConsult,
    'readyForDoctor' => l10n.statusReadyForDoctor,
    'confirmed' => l10n.statusConfirmed,
    'checkedIn' => l10n.statusCheckedIn,
    'pending' => l10n.statusPending,
    'booked' => l10n.statusBooked,
    'noShow' => l10n.statusNoShow,
    'missed' => l10n.statusMissed,
    'refundPending' => l10n.statusRefundPending,
    'refunded' => l10n.statusRefunded,
    'followupAvailable' => l10n.statusFollowupAvailable,
    'followupUsed' => l10n.statusFollowupUsed,
    'followupExpired' => l10n.statusFollowupExpired,
    'rescheduledOnce' => l10n.statusRescheduledOnce,
    'expired' => l10n.statusExpired,
    'closed' => l10n.statusClosed,
    _ => l10n.statusUpcoming,
  };
}

class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({
    super.key,
    required this.appointment,
    this.doctorStatus,
    this.compact = false,
    this.isNextUp = false,
    this.lifecycleStatus,
  });

  final AppointmentModel appointment;
  final String? doctorStatus;
  final bool compact;
  final bool isNextUp;
  final String? lifecycleStatus;

  @override
  Widget build(BuildContext context) {
    final info = resolveAppointmentStatus(
      appointment,
      doctorStatusOverride: doctorStatus,
      isNextUp: isNextUp,
      lifecycleStatusOverride: lifecycleStatus,
      labelFor: (key) => appointmentStatusLabelFor(context, key),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: info.textColor.withValues(alpha: context.isDark ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            info.label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: info.textColor,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              color: info.textColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
