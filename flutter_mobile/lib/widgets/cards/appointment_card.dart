import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../utils/date_formatter.dart';
import '../../utils/theme_context.dart';
import '../appointments/live_queue_panel.dart';
import '../common/appointment_status_chip.dart';
import '../common/appointment_action_buttons.dart';
import '../common/avatar_image.dart';

/// Appointment list card — tap info to open details; Calendar / Cancel on card.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.showBadge = true,
    this.showLiveQueue = true,
    this.onTap,
    this.onCancel,
    this.onAddToCalendar,
    this.onJoinVideo,
  });

  final AppointmentModel appointment;
  final bool showBadge;
  final bool showLiveQueue;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onJoinVideo;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = appointment.isUpcoming;

    final showJoin = isUpcoming && appointment.isOnlineVisit && onJoinVideo != null;
    final showActions = isUpcoming && (onAddToCalendar != null || onCancel != null);

    final showStatusChip = showBadge || appointment.isCompleted || appointment.cancelled;

    Widget info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.specCircleFill, width: 2),
            borderRadius: BorderRadius.circular(28),
          ),
          child: AvatarImage(uri: appointment.doctorImageUrl, size: 44),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.doctorName,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              if (appointment.specialization.isNotEmpty)
                Text(
                  appointment.specialization,
                  style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: AppColors.logoTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.patientLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.logoTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: context.secondaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${DateFormatter.formatSlotDate(appointment.slotDate)} • ${DateFormatter.displayTime(appointment.slotTime)}',
                      style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                    ),
                  ),
                ],
              ),
              if (appointment.hospitalName != null && appointment.hospitalName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, size: 12, color: context.secondaryText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.hospitalName!,
                        style: GoogleFonts.poppins(fontSize: 11, color: context.secondaryText),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (showStatusChip)
          AppointmentStatusChip(appointment: appointment, compact: true),
      ],
    );

    if (onTap != null) {
      info = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: info),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          info,
          if (showLiveQueue && isUpcoming)
            LiveQueuePanel(appointment: appointment, mode: LiveQueuePanelMode.compact),
          if (showJoin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onJoinVideo,
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: Text(
                  'Join Video Call',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onAddToCalendar != null)
                  Expanded(
                    child: AppointmentActionChip(
                      icon: Icons.event_available_outlined,
                      label: 'Calendar',
                      color: AppColors.primaryBlue,
                      onTap: onAddToCalendar!,
                    ),
                  ),
                if (onAddToCalendar != null && onCancel != null) const SizedBox(width: 8),
                if (onCancel != null)
                  Expanded(
                    child: AppointmentActionChip(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel',
                      color: AppColors.error,
                      onTap: onCancel!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
