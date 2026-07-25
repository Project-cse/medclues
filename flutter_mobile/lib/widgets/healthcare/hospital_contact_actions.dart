import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/contact_navigation_utils.dart';
import '../common/app_snackbar.dart';
import 'premium_healthcare_theme.dart';

/// Navigate + Call row for hospital detail page.
class HospitalContactActions extends StatelessWidget {
  const HospitalContactActions({
    super.key,
    required this.hospitalName,
    required this.address,
    this.phone,
    this.mapsLink,
  });

  final String hospitalName;
  final String address;
  final String? phone;
  final String? mapsLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        12,
        PremiumHealthcareTheme.horizontalPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Btn(
              icon: Icons.navigation_rounded,
              label: 'Navigate',
              color: PremiumHealthcareTheme.primaryBlue,
              onTap: () async {
                final ok = await ContactNavigationUtils.openHospitalNavigation(
                  hospitalName: hospitalName,
                  address: address,
                  mapsLink: mapsLink,
                );
                if (!context.mounted) return;
                if (!ok) AppSnackbar.show(context, 'Address not available');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Btn(
              icon: Icons.call_rounded,
              label: 'Call clinic',
              color: const Color(0xFF16A34A),
              onTap: () async {
                final ok = await ContactNavigationUtils.callClinic(phone);
                if (!context.mounted) return;
                if (!ok) AppSnackbar.show(context, 'Phone number not available');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PremiumHealthcareTheme.white(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
