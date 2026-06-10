import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../utils/date_formatter.dart';
import '../../utils/theme_context.dart';
import '../common/avatar_image.dart';

/// Matches mobile/components/cards/AppointmentCard.tsx
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.showBadge = true,
    this.onTap,
    this.onCancel,
    this.onAddToCalendar,
  });

  final AppointmentModel appointment;
  final bool showBadge;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = appointment.isUpcoming;

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Row(
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
                if (onAddToCalendar != null && isUpcoming) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAddToCalendar,
                      icon: const Icon(Icons.event_available_outlined, size: 16),
                      label: Text(
                        'Calendar',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
                if (onCancel != null && isUpcoming) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showBadge && isUpcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: context.isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                appointment.status == 'pending' ? 'Pending' : 'Upcoming',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.isDark ? const Color(0xFFFCD34D) : AppColors.warning,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card),
      );
    }
    return card;
  }
}
