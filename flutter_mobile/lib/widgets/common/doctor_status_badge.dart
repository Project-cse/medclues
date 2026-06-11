import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/doctor_model.dart';

/// Online / offline / in-clinic indicator.
class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({super.key, required this.doctor, this.compact = false});

  final DoctorModel doctor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = doctor.onlineStatusLabel;
    final color = doctor.isOnline ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);
    final bg = doctor.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
