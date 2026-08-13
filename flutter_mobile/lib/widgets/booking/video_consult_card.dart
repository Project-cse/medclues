import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/vc_slot_window.dart';

/// Compact post-booking card for online / video consults (not full hospital receipt).
class VideoConsultCard extends StatelessWidget {
  const VideoConsultCard({
    super.key,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    this.bookingId,
    this.specialization,
    this.amount,
    this.statusLine,
    this.canJoin = false,
    this.joinLabel = 'Join Video',
    this.onJoin,
    this.onAddToCalendar,
  });

  final String doctorName;
  final String appointmentDate;
  final String appointmentTime;
  final String? bookingId;
  final String? specialization;
  final double? amount;
  final String? statusLine;
  final bool canJoin;
  final String joinLabel;
  final VoidCallback? onJoin;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final qr = (bookingId ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoTeal.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'VIDEO CONSULT',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            doctorName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (specialization != null && specialization!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              specialization!,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$appointmentDate · $appointmentTime',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (amount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(amount!),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                if (qr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: qr.toUpperCase(),
                      size: 72,
                      backgroundColor: Colors.white,
                    ),
                  ),
                if (qr.isNotEmpty) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ID',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        qr.isNotEmpty ? qr.toUpperCase() : '—',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusLine ?? 'Join opens at slot start',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canJoin ? onJoin : null,
              icon: const Icon(Icons.videocam_rounded, size: 20),
              label: Text(
                joinLabel,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandNavy,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (onAddToCalendar != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddToCalendar,
              icon: const Icon(Icons.event_available_outlined, color: Colors.white70, size: 18),
              label: Text(
                'Add to calendar',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build join gating from local slot times when server window is unavailable.
  static ({bool canJoin, String label, String status}) joinState({
    required String slotDate,
    required String slotTime,
  }) {
    final w = VcSlotWindow.fromSlot(slotDate: slotDate, slotTime: slotTime);
    return (
      canJoin: w.canJoinWindow && !w.forceEnd,
      label: w.joinButtonLabel,
      status: w.windowMessage ?? (w.canJoinWindow ? 'Ready to join' : 'Join opens at slot start'),
    );
  }
}
