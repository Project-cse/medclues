import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../emergency_constants.dart';

class EmergencyActionButton extends StatelessWidget {
  const EmergencyActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = true,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? EmergencyConstants.emergencyRed : Colors.white;
    final fg = filled ? Colors.white : EmergencyConstants.emergencyRedDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        elevation: filled ? 3 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: filled ? Colors.white70 : EmergencyConstants.emergencyText,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: fg.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
