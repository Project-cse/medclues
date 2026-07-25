import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/doctor_model.dart';

/// Status badge — labels match Dean portal (available / busy / emergency / unavailable).
class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({super.key, required this.doctor, this.compact = false});

  final DoctorModel doctor;
  final bool compact;

  ({Color fg, Color bg}) _colors() {
    final key = doctor.status?.toLowerCase().trim() ?? '';
    switch (key) {
      case 'emergency':
        return (fg: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2));
      case 'busy':
        return (fg: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
      case 'inactive':
      case 'unavailable':
      case 'offline':
        return (fg: const Color(0xFF6B7280), bg: const Color(0xFFF3F4F6));
      case 'in-clinic':
      case 'in_clinic':
        return (fg: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE));
      default:
        if (doctor.isOnline) {
          return (fg: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7));
        }
        return (fg: const Color(0xFF9CA3AF), bg: const Color(0xFFF3F4F6));
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = doctor.onlineStatusLabel;
    final colors = _colors();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: colors.fg,
            ),
          ),
        ],
      ),
    );
  }
}
