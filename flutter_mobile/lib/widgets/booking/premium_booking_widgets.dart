import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/doctor_model.dart';
import '../../utils/image_url_helper.dart';
import '../common/avatar_image.dart';
import 'premium_booking_theme.dart';
import 'premium_symptom_chip.dart';

class PremiumBookingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumBookingAppBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            _BackButton(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PremiumBookingTheme.text(context),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: PremiumBookingTheme.white(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PremiumBookingTheme.border(context)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: PremiumBookingTheme.primaryBlue,
        ),
      ),
    );
  }
}

class PremiumDoctorBookingCard extends StatelessWidget {
  const PremiumDoctorBookingCard({super.key, required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final exp = doctor.experienceLabel?.isNotEmpty == true
        ? doctor.experienceLabel!
        : (doctor.experienceYears > 0 ? '${doctor.experienceYears} Years Experience' : null);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PremiumBookingTheme.corporateCard(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PremiumBookingTheme.accentBlue.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: AvatarImage(uri: resolveImageUrl(doctor.imageUrl), size: 68),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: PremiumBookingTheme.text(context),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialization,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: PremiumBookingTheme.textSecondary(context),
                  ),
                ),
                if (exp != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 16, color: PremiumBookingTheme.accentBlue),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          exp,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PremiumBookingTheme.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (doctor.hasRating) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: PremiumBookingTheme.starGold),
                      const SizedBox(width: 4),
                      Text(
                        doctor.displayRatingText ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PremiumBookingTheme.text(context),
                        ),
                      ),
                      if (doctor.reviewCount != null && doctor.reviewCount! > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} Reviews)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PremiumBookingTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumBookingSectionHeader extends StatelessWidget {
  const PremiumBookingSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: PremiumBookingTheme.accentBlue),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: PremiumBookingTheme.sectionTitleStyle(context),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: PremiumBookingTheme.border(context)),
      ],
    );
  }
}

class PremiumViewCalendarAction extends StatelessWidget {
  const PremiumViewCalendarAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: PremiumBookingTheme.chipSelectedBg(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: PremiumBookingTheme.accentBlue.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined, size: 16, color: PremiumBookingTheme.accentBlue),
            const SizedBox(width: 6),
            Text(
              'View Calendar',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PremiumBookingTheme.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumSymptomsCard extends StatelessWidget {
  const PremiumSymptomsCard({
    super.key,
    required this.specialization,
    required this.symptoms,
    required this.selected,
    required this.onToggle,
  });

  final String specialization;
  final List<String> symptoms;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PremiumBookingTheme.corporateCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: PremiumBookingTheme.iconBadge(context),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: PremiumBookingTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Symptoms',
                      style: PremiumBookingTheme.sectionTitleStyle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose symptoms relevant to $specialization',
                      style: PremiumBookingTheme.sectionSubtitleStyle(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: PremiumBookingTheme.border(context)),
          const SizedBox(height: 16),
          symptomsCardGrid(symptoms, selected, onToggle),
        ],
      ),
    );
  }
}

Widget symptomsCardGrid(
  List<String> symptoms,
  Set<String> selected,
  ValueChanged<String> onToggle,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      const cols = 3;
      const gap = 8.0;
      final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: symptoms.map((s) {
          final isOn = selected.contains(s);
          return SizedBox(
            width: cellW,
            child: PremiumSymptomChip(
              label: s,
              selected: isOn,
              onTap: () => onToggle(s),
            ),
          );
        }).toList(),
      );
    },
  );
}

class PremiumSecurityCard extends StatelessWidget {
  const PremiumSecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PremiumBookingTheme.securityBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumBookingTheme.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: PremiumBookingTheme.iconBadge(context),
            child: const Icon(Icons.shield_outlined, size: 18, color: PremiumBookingTheme.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your information is 100% secure',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PremiumBookingTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We follow industry-standard security practices to protect your data.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PremiumBookingTheme.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumBookAppointmentCta extends StatelessWidget {
  const PremiumBookAppointmentCta({
    super.key,
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        PremiumBookingTheme.horizontalPadding,
        12,
        PremiumBookingTheme.horizontalPadding,
        20,
      ),
      decoration: BoxDecoration(
        color: PremiumBookingTheme.white(context),
        border: Border(
          top: BorderSide(color: PremiumBookingTheme.border(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            height: PremiumBookingTheme.buttonHeight,
            decoration: BoxDecoration(
              gradient: active ? PremiumBookingTheme.ctaGradient : null,
              color: active ? null : PremiumBookingTheme.border(context),
              borderRadius: BorderRadius.circular(PremiumBookingTheme.buttonRadius),
              boxShadow: active ? PremiumBookingTheme.ctaShadow : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: active ? onPressed : null,
                borderRadius: BorderRadius.circular(PremiumBookingTheme.buttonRadius),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 22,
                              color: active ? Colors.white : PremiumBookingTheme.textSecondary(context),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : PremiumBookingTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
