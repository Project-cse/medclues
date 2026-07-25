import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../utils/contact_navigation_utils.dart';
import '../common/app_snackbar.dart';

/// Styled chip for appointment card actions (Navigate, Call, Calendar, Cancel).
class AppointmentActionChip extends StatelessWidget {
  const AppointmentActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.height = 34,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigate + Call clinic row for appointment detail screen.
class AppointmentActionButtons extends StatelessWidget {
  const AppointmentActionButtons({
    super.key,
    required this.appointment,
    this.compact = true,
  });

  final AppointmentModel appointment;
  final bool compact;

  Future<void> _navigate(BuildContext context) async {
    final ok = await ContactNavigationUtils.openHospitalNavigation(
      hospitalName: appointment.hospitalName,
      location: appointment.location,
      address: appointment.location,
    );
    if (!context.mounted) return;
    if (!ok) {
      AppSnackbar.show(context, 'Location not available for navigation');
    }
  }

  Future<void> _call(BuildContext context) async {
    final ok = await ContactNavigationUtils.callClinic(appointment.clinicPhone);
    if (!context.mounted) return;
    if (!ok) {
      AppSnackbar.show(context, 'Clinic phone number not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!appointment.isUpcoming) return const SizedBox.shrink();

    final height = compact ? 34.0 : 40.0;
    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 12),
      child: Row(
        children: [
          Expanded(
            child: AppointmentActionChip(
              icon: Icons.navigation_rounded,
              label: 'Navigate',
              height: height,
              color: AppColors.primaryBlue,
              onTap: () => _navigate(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppointmentActionChip(
              icon: Icons.call_rounded,
              label: 'Call clinic',
              height: height,
              color: const Color(0xFF16A34A),
              onTap: () => _call(context),
            ),
          ),
        ],
      ),
    );
  }
}
