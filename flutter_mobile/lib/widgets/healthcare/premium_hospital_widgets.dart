import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/doctor_model.dart';
import '../../utils/hospital_stats.dart';
import '../../utils/image_url_helper.dart';
import '../common/avatar_image.dart';
import '../common/doctor_status_badge.dart';
import 'premium_healthcare_theme.dart';

const kHospitalBuildingAsset = 'assets/images/hospital_building.png';

class PremiumHospitalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumHospitalAppBar({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PremiumHealthcareTheme.white(context),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back_rounded, color: PremiumHealthcareTheme.text(context), size: 22),
              ),
              Expanded(
                child: Text(
                  'Hospital',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PremiumHealthcareTheme.text(context),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumHospitalHeroCard extends StatelessWidget {
  const PremiumHospitalHeroCard({
    super.key,
    required this.badge,
    required this.name,
    this.subtitle,
    required this.address,
    this.phone,
    this.backgroundImageUrl,
  });

  final String badge;
  final String name;
  final String? subtitle;
  final String address;
  final String? phone;

  /// Optional uploaded banner image URL. When present it is shown as the card
  /// background with a dark/blue gradient overlay so text stays readable.
  /// Falls back to the default building asset / teal gradient when null.
  final String? backgroundImageUrl;

  Widget _defaultAsset() {
    return Image.asset(
      kHospitalBuildingAsset,
      fit: BoxFit.cover,
      alignment: const Alignment(0.18, 0),
      filterQuality: FilterQuality.high,
      errorBuilder: (_, error, __) {
        debugPrint('Failed to load $kHospitalBuildingAsset: $error');
        return const DecoratedBox(
          decoration: BoxDecoration(gradient: _heroShadeGradient),
        );
      },
    );
  }

  Widget _buildBackground() {
    final url = backgroundImageUrl?.trim();
    if (url == null || url.isEmpty) {
      // Default building banner already includes the left blue shade.
      return _defaultAsset();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _defaultAsset(),
        ),
        // Dark/blue overlay for readability over an arbitrary photo.
        const DecoratedBox(decoration: BoxDecoration(gradient: _heroOverlayGradient)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PremiumHealthcareTheme.horizontalPadding),
      height: 208,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumHealthcareTheme.cardRadius),
        boxShadow: PremiumHealthcareTheme.cardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumHealthcareTheme.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.56,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (address.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withValues(alpha: 0.92)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.94),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (phone != null && phone!.isNotEmpty && phone != 'Not available') ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: Colors.white.withValues(alpha: 0.92)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                phone!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.94),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark/blue overlay drawn on top of an uploaded banner image so the hospital
/// name, specialization, address and phone remain readable.
const _heroOverlayGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xE60A1B2A),
    Color(0xB3091A29),
    Color(0x4D0A1B2A),
  ],
  stops: [0.0, 0.5, 1.0],
);

/// Fallback when the banner asset fails to load.
const _heroShadeGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    PremiumHealthcareTheme.primaryBlue,
    Color(0xE6003B8E),
    Color(0x99003B8E),
    Color(0x33003B8E),
    Colors.transparent,
  ],
  stops: [0.0, 0.22, 0.38, 0.52, 0.68],
);

class PremiumHospitalStatsRow extends StatelessWidget {
  const PremiumHospitalStatsRow({super.key, required this.stats});

  final HospitalComputedStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        20,
        PremiumHealthcareTheme.horizontalPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.people_outline_rounded,
              value: stats.doctorCountLabel,
              label: 'Doctors',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.medical_services_outlined,
              value: stats.emergencyLabel,
              label: 'Emergency',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.favorite_border_rounded,
              value: stats.departmentCountLabel,
              label: 'Departments',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.star_outline_rounded,
              value: stats.ratingLabel,
              label: 'Patient Rating',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: PremiumHealthcareTheme.secondaryBlue.withValues(alpha: 0.35)),
            color: PremiumHealthcareTheme.white(context),
          ),
          child: Icon(icon, size: 20, color: PremiumHealthcareTheme.secondaryBlue),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: PremiumHealthcareTheme.text(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: PremiumHealthcareTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

class PremiumDoctorsSectionHeader extends StatelessWidget {
  const PremiumDoctorsSectionHeader({
    super.key,
    required this.count,
    this.showViewAll = false,
    this.onViewAll,
  });

  final int count;
  final bool showViewAll;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        28,
        PremiumHealthcareTheme.horizontalPadding,
        14,
      ),
      child: Row(
        children: [
          Text(
            'Our Doctors',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: PremiumHealthcareTheme.text(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: PremiumHealthcareTheme.primaryBlue,
            ),
          ),
          const Spacer(),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PremiumHealthcareTheme.secondaryBlue,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: PremiumHealthcareTheme.secondaryBlue,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumHospitalDoctorCard extends StatelessWidget {
  const PremiumHospitalDoctorCard({
    super.key,
    required this.doctor,
    required this.onBook,
  });

  final DoctorModel doctor;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final name = doctor.name.startsWith('Dr.') ? doctor.name : 'Dr. ${doctor.name}';
    final bookable = doctor.isBookable;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        0,
        PremiumHealthcareTheme.horizontalPadding,
        12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PremiumHealthcareTheme.white(context),
        borderRadius: BorderRadius.circular(PremiumHealthcareTheme.doctorCardRadius),
        border: Border.all(color: PremiumHealthcareTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarImage(uri: resolveImageUrl(doctor.imageUrl), size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PremiumHealthcareTheme.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialization,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PremiumHealthcareTheme.textSecondary(context),
                  ),
                ),
                if (doctor.hasRating) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        doctor.displayRatingText!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: PremiumHealthcareTheme.text(context),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                DoctorStatusBadge(doctor: doctor, compact: true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: SizedBox(
              height: PremiumHealthcareTheme.bookBtnHeight,
              child: ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumHealthcareTheme.navyButton,
                  disabledBackgroundColor: PremiumHealthcareTheme.border(context),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: PremiumHealthcareTheme.textSecondary(context),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Book Appointment',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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

class PremiumHospitalTrustBanner extends StatelessWidget {
  const PremiumHospitalTrustBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        8,
        PremiumHealthcareTheme.horizontalPadding,
        0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumHealthcareTheme.secondaryBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PremiumHealthcareTheme.white(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PremiumHealthcareTheme.secondaryBlue.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.verified_user_outlined, size: 22, color: PremiumHealthcareTheme.secondaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your health is our priority',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PremiumHealthcareTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We maintain the highest standards of safety and care.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: PremiumHealthcareTheme.textSecondary(context),
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
