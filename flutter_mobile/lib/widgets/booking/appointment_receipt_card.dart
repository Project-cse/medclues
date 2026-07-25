import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_colors.dart';
import '../animations/healthcare_motion.dart';
import '../../utils/receipt_location_helper.dart';

/// Mockup-style appointment receipt (no prescription section).
class AppointmentReceiptCard extends StatelessWidget {
  const AppointmentReceiptCard({
    super.key,
    this.bookingId,
    required this.patientName,
    required this.doctorName,
    required this.specialization,
    required this.appointmentDate,
    required this.appointmentTime,
    this.tokenNumber,
    this.hospitalName,
    this.location,
    this.roomNo,
    this.visitType = 'In-clinic',
    this.status = 'Confirmed',
    this.amountLabel,
    this.showConfirmationBanner = true,
    this.onWhatsApp,
    this.onEmail,
    this.onPrint,
  });

  final String? bookingId;

  bool get _hasBookingId => bookingId != null && bookingId!.trim().isNotEmpty;
  final int? tokenNumber;
  final String patientName;
  final String doctorName;
  final String specialization;
  final String? hospitalName;
  final String? location;
  final String? roomNo;
  final String appointmentDate;
  final String appointmentTime;
  final String visitType;
  final String status;
  final String? amountLabel;
  final bool showConfirmationBanner;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onEmail;
  final VoidCallback? onPrint;

  static const _greenBanner = Color(0xFFECFDF5);
  static const _greenText = Color(0xFF059669);
  static const _tokenBg = Color(0xFFEFF6FF);
  static const _tokenBlue = Color(0xFF2563EB);
  static const _tokenFooter = Color(0xFF1D4ED8);

  String get _tokenLabel {
    if (tokenNumber != null && tokenNumber! > 0) return 'A-$tokenNumber';
    return '—';
  }

  String get _hospital =>
      hospitalName?.trim().isNotEmpty == true ? hospitalName! : 'MedClues Network';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showConfirmationBanner) ...[
          _confirmationBanner().receiptLine(0),
          const SizedBox(height: 16),
        ],
        _ticketSection()
            .animate()
            .slideY(begin: 0.14, end: 0, duration: 520.ms, curve: HealthcareMotion.easeOut)
            .fadeIn(duration: 450.ms),
        const SizedBox(height: 16),
        _appointmentDetailsCard(),
        if (onWhatsApp != null || onEmail != null || onPrint != null) ...[
          const SizedBox(height: 20),
          _shareSection().receiptLine(5),
        ],
      ],
    )
        .animate()
        .slideY(begin: 0.08, end: 0, duration: 480.ms, curve: HealthcareMotion.easeOut)
        .fadeIn(duration: 400.ms);
  }

  Widget _confirmationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _greenBanner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: _greenText, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your appointment is confirmed',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _greenText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thank you! We look forward to seeing you.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_outlined, color: _greenText.withValues(alpha: 0.5), size: 28),
        ],
      ),
    );
  }

  static const _ticketHeight = 290.0;

  Widget _ticketSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: _ticketHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 11, child: _tokenHalf()),
            _ticketDivider(),
            Expanded(flex: 10, child: _qrHalf()),
          ],
        ),
      ),
    );
  }

  Widget _tokenHalf() {
    return ColoredBox(
      color: _tokenBg,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('*', style: GoogleFonts.poppins(fontSize: 10, color: _tokenBlue.withValues(alpha: 0.5))),
                      const SizedBox(width: 5),
                      Text(
                        'TOKEN NUMBER',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _tokenBlue.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text('*', style: GoogleFonts.poppins(fontSize: 10, color: _tokenBlue.withValues(alpha: 0.5))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dashedLine(),
                  const SizedBox(height: 10),
                  Text(
                    _tokenLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _tokenBlue,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dashedLine(),
                  const SizedBox(height: 8),
                  Text(
                    'Show this token at the clinic',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_hasBookingId) ...[
                    const SizedBox(height: 4),
                    Text(
                      bookingId!.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _tokenBlue.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            color: _tokenFooter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 15),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Please arrive 15 mins early',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor().clamp(4, 24);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < count - 1 ? gap : 0),
              child: Container(
                width: dashWidth,
                height: 1.5,
                color: _tokenBlue.withValues(alpha: 0.35),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _ticketDivider() {
    return SizedBox(
      width: 26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...List.generate(8, (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Container(width: 2, height: 5, color: const Color(0xFFCBD5E1)),
              )),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(Icons.link, size: 13, color: _tokenBlue.withValues(alpha: 0.65)),
          ),
          ...List.generate(8, (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Container(width: 2, height: 5, color: const Color(0xFFCBD5E1)),
              )),
        ],
      ),
    );
  }

  Widget _qrHalf() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _qrWidget(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: _tokenBlue, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                'SCAN AT RECEPTION',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _tokenBlue,
                ),
              ),
              const SizedBox(width: 5),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: _tokenBlue, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: _tokenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, size: 16, color: _tokenBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure & Verified',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _tokenBlue,
                        ),
                      ),
                      Text(
                        'This QR is unique to your appointment',
                        style: GoogleFonts.poppins(fontSize: 8, color: _tokenBlue.withValues(alpha: 0.85), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrWidget() {
    if (_hasBookingId) {
      return SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: bookingId!.toUpperCase(),
              size: 108,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _tokenBlue,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 16),
            ),
          ],
        ),
      )
          .animate(delay: 180.ms)
          .scale(begin: const Offset(0.82, 0.82), end: const Offset(1, 1), duration: 480.ms, curve: HealthcareMotion.easeOut)
          .fadeIn(duration: 400.ms);
    }

    return Container(
      width: 108,
      height: 108,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 40, color: _tokenBlue.withValues(alpha: 0.4)),
          const SizedBox(height: 6),
          Text(
            'QR ready soon',
            style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ReceiptLocationInfo get _locationInfo => parseReceiptLocation(
        addressLine1: location,
        addressLine2: roomNo,
        hospitalName: hospitalName,
      );

  Widget _appointmentDetailsCard() {
    final dateTimeLine = '$appointmentDate • $appointmentTime';
    final locInfo = _locationInfo;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _detailRow(
            icon: Icons.medical_services_outlined,
            iconBg: const Color(0xFFDBEAFE),
            iconColor: _tokenBlue,
            label: 'Doctor',
            title: doctorName,
            subtitle: specialization,
          ).receiptLine(1),
          const Divider(height: 1, indent: 72),
          _detailRow(
            icon: Icons.calendar_month_outlined,
            iconBg: const Color(0xFFD1FAE5),
            iconColor: _greenText,
            label: 'Date & Time',
            title: dateTimeLine,
            subtitle: 'Patient: $patientName',
          ).receiptLine(2),
          const Divider(height: 1, indent: 72),
          _detailRow(
            icon: Icons.local_hospital_outlined,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
            label: 'Hospital',
            title: _hospital,
          ).receiptLine(3),
          if (locInfo.hasRoom) ...[
            const Divider(height: 1, indent: 72),
            _detailRow(
              icon: Icons.meeting_room_outlined,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
              label: 'Room No.',
              title: locInfo.roomNo!,
            ).receiptLine(4),
          ],
          if (locInfo.hasFloor) ...[
            const Divider(height: 1, indent: 72),
            _detailRow(
              icon: Icons.layers_outlined,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
              label: 'Floor / Location',
              title: locInfo.floorOrLocation!,
            ).receiptLine(4),
          ],
          if (amountLabel != null) ...[
            const Divider(height: 1, indent: 72),
            _detailRow(
              icon: Icons.payments_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              label: 'Fee',
              title: amountLabel!,
              subtitle: status,
            ).receiptLine(5),
          ],
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Receipt',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (onWhatsApp != null)
              Expanded(
                child: _shareChip(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  onTap: onWhatsApp!,
                ),
              ),
            if (onWhatsApp != null && (onEmail != null || onPrint != null)) const SizedBox(width: 10),
            if (onEmail != null)
              Expanded(
                child: _shareChip(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: onEmail!,
                ),
              ),
            if (onEmail != null && onPrint != null) const SizedBox(width: 10),
            if (onPrint != null)
              Expanded(
                child: _shareChip(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  onTap: onPrint!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _shareChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppColors.brandNavy),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
