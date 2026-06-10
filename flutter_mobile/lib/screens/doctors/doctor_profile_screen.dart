import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/theme_context.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/image_url_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/avatar_image.dart';

/// Doctor profile — video consult + in-clinic booking (matches reference UI).
class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  String get doctorId => widget.doctorId;

  void _openInClinicBooking(BuildContext context) {
    context.push('/booking/patient/$doctorId');
  }

  void _openVideoBooking(BuildContext context) {
    context.push('/booking/patient/$doctorId?visit=online');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));
    ref.listen(doctorDetailProvider(doctorId), (prev, next) {
      next.whenData((_) {
        prefetchDoctorSchedule(ref, doctorId, mode: 'offline');
        prefetchDoctorSchedule(ref, doctorId, mode: 'online');
      });
    });

    return Scaffold(
      body: doctorAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(doctorDetailProvider(doctorId)),
        ),
        data: (doctor) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: AppColors.error),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    AvatarImage(uri: resolveImageUrl(doctor.imageUrl), size: 140),
                    const SizedBox(height: 16),
                    Text(
                      doctor.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.specCircleFill),
                        const SizedBox(width: 6),
                        Text(
                          doctor.specialization,
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.specCircleFill),
                        ),
                      ],
                    ),
                    if (doctor.hospitalName != null && doctor.hospitalName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        doctor.hospitalName!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14, color: context.secondaryText),
                      ),
                    ],
                    if (doctor.experienceLabel != null && doctor.experienceLabel!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.highlightBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${doctor.experienceLabel} ${l10n.doctorExperience}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.isDark ? context.cs.primary : AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                    if (doctor.hasRating) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: AppColors.starBright, size: 16),
                          Text(
                            ' ${doctor.rating!.toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: context.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (doctor.consultationFee > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.doctorFees}: ${CurrencyFormatter.format(doctor.consultationFee)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _DoctorActionButton(
                          icon: Icons.videocam_outlined,
                          label: l10n.videoConsult,
                          onTap: () => _openVideoBooking(context),
                        ),
                        _DoctorActionButton(
                          icon: Icons.share_outlined,
                          label: l10n.doctorShare,
                          onTap: () {
                            Share.share('${l10n.bookAppointment} - ${doctor.name}');
                          },
                        ),
                      ],
                    ),
                    if (doctor.about != null && doctor.about!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.doctorAbout,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          doctor.about!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.5,
                            color: context.secondaryText,
                          ),
                        ),
                      ),
                    ],
                    if (doctor.degree != null && doctor.degree!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.doctorEducation,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          doctor.degree!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.5,
                            color: context.secondaryText,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          l10n.doctorAvailability,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.doctorAvailabilityDays,
                        style: GoogleFonts.poppins(fontSize: 14, color: context.secondaryText),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.doctorAvailabilityTime,
                        style: GoogleFonts.poppins(fontSize: 14, color: context.secondaryText),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: l10n.bookAppointment,
                      onPressed: () => _openInClinicBooking(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Neutral by default — blue highlight only on hover or press.
class _DoctorActionButton extends StatefulWidget {
  const _DoctorActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_DoctorActionButton> createState() => _DoctorActionButtonState();
}

class _DoctorActionButtonState extends State<_DoctorActionButton> {
  static const _accent = Color(0xFF2563EB);
  static const _accentBg = Color(0xFFF0F7FF);

  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || _pressed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final active = _active;

    final bg = active
        ? (isDark ? const Color(0xFF0C4A6E) : _accentBg)
        : (isDark ? context.cardColor : Colors.white);
    final border = active
        ? (isDark ? context.cs.primary : _accent.withValues(alpha: 0.35))
        : context.borderColor;
    final iconColor = active
        ? (isDark ? context.cs.primary : _accent)
        : context.secondaryText;
    final labelColor = active
        ? (isDark ? context.cs.primary : const Color(0xFF003B8E))
        : context.primaryText;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
                boxShadow: active && !isDark
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(widget.icon, color: iconColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
