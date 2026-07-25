import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/hospital_model.dart';
import '../../themes/premium_theme_colors.dart';
import '../../utils/hospital_display_utils.dart';
import '../../utils/image_url_helper.dart';
import '../../utils/location_utils.dart';
import 'premium_hospital_widgets.dart';

/// MEDCLUES 2026 — world-class hospital directory design tokens.
abstract final class PremiumHospitalDirectoryTheme {
  static const Color medicalBlue = Color(0xFF003B8E);
  static const Color actionBlue = Color(0xFF2563EB);
  static const Color healthcareTeal = Color(0xFF00B8B0);
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color verifiedGreen = Color(0xFF22C55E);
  static const Color starGold = Color(0xFFF59E0B);

  static Color white(BuildContext context) =>
      PremiumThemeColors.of(context).surface;
  static Color background(BuildContext context) =>
      PremiumThemeColors.of(context).background;
  static Color text(BuildContext context) => PremiumThemeColors.of(context).text;
  static Color textSecondary(BuildContext context) =>
      PremiumThemeColors.of(context).textSecondary;
  static Color border(BuildContext context) =>
      PremiumThemeColors.of(context).border;

  static const double horizontalPadding = 16;
  static const double cardRadius = 20;
  static const double segmentRadius = 30;

  static List<BoxShadow> cardShadow(BuildContext context) => [
        BoxShadow(
          color: medicalBlue.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.04,
          ),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> segmentShadow(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
          ),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class PremiumHospitalDirectoryHeader extends StatelessWidget {
  const PremiumHospitalDirectoryHeader({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.onFilter,
    this.onBack,
    this.filterCount = 0,
  });

  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilter;
  final VoidCallback? onBack;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PremiumHospitalDirectoryTheme.medicalBlue,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                  Text(
                    'Hospitals',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: onFilter,
                        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      ),
                      if (filterCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: PremiumHospitalDirectoryTheme.healthcareTeal,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$filterCount',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search hospitals...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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

class PremiumHospitalSegmentedSwitch extends StatelessWidget {
  const PremiumHospitalSegmentedSwitch({
    super.key,
    required this.showNearby,
    required this.onAllTap,
    required this.onNearbyTap,
  });

  final bool showNearby;
  final VoidCallback onAllTap;
  final VoidCallback onNearbyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumHospitalDirectoryTheme.horizontalPadding,
        16,
        PremiumHospitalDirectoryTheme.horizontalPadding,
        8,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: PremiumHospitalDirectoryTheme.white(context),
          borderRadius: BorderRadius.circular(PremiumHospitalDirectoryTheme.segmentRadius),
          boxShadow: PremiumHospitalDirectoryTheme.segmentShadow(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentTab(
                label: 'All Hospitals',
                icon: Icons.local_hospital_outlined,
                selected: !showNearby,
                onTap: onAllTap,
              ),
            ),
            Expanded(
              child: _SegmentTab(
                label: 'Nearby Hospitals',
                icon: Icons.location_on_outlined,
                selected: showNearby,
                onTap: onNearbyTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PremiumHospitalDirectoryTheme.actionBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(PremiumHospitalDirectoryTheme.segmentRadius - 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PremiumHospitalDirectoryTheme.segmentRadius - 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : PremiumHospitalDirectoryTheme.actionBlue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : PremiumHospitalDirectoryTheme.actionBlue,
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

class PremiumHospitalDirectoryCard extends StatelessWidget {
  const PremiumHospitalDirectoryCard({
    super.key,
    required this.hospital,
    required this.onDetails,
    this.onBook,
    this.showDistance = false,
  });

  final HospitalModel hospital;
  final VoidCallback onDetails;
  final VoidCallback? onBook;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    final chips = parseHospitalSpecializationChips(hospital.specialization);
    final visibleChips = chips.take(3).toList();
    final extraChips = chips.length - visibleChips.length;
    final hasRating = hospital.rating != null && hospital.rating! > 0;
    final hasDistance = hospital.distanceKm != null && (showDistance || hospital.distanceKm! > 0);
    final isVerified = hospital.canOpenDetails;
    final hasDoctors = hospital.doctorCount != null && hospital.doctorCount! > 0;
    final hasEmergency = hospital.emergencyAvailable == true;
    final imageUri = resolveImageUrl(
      (hospital.backgroundImage?.trim().isNotEmpty ?? false)
          ? hospital.backgroundImage
          : hospital.imageUrl,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetails,
          borderRadius: BorderRadius.circular(PremiumHospitalDirectoryTheme.cardRadius),
          child: Container(
        decoration: BoxDecoration(
          color: PremiumHospitalDirectoryTheme.white(context),
          borderRadius: BorderRadius.circular(PremiumHospitalDirectoryTheme.cardRadius),
          border: Border.all(color: PremiumHospitalDirectoryTheme.border(context).withValues(alpha: 0.6)),
          boxShadow: PremiumHospitalDirectoryTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HospitalThumbnail(imageUri: imageUri),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    hospital.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: PremiumHospitalDirectoryTheme.text(context),
                                      height: 1.2,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: PremiumHospitalDirectoryTheme.actionBlue,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: PremiumHospitalDirectoryTheme.verifiedGreen.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Verified Hospital',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: PremiumHospitalDirectoryTheme.verifiedGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (hasDistance) ...[
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatDistanceKm(hospital.distanceKm!),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: PremiumHospitalDirectoryTheme.actionBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.directions_car_filled_outlined,
                                        size: 11,
                                        color: PremiumHospitalDirectoryTheme.textSecondary(context).withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        formatHospitalTravelTime(hospital.distanceKm!),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: PremiumHospitalDirectoryTheme.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        if (hasRating) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: PremiumHospitalDirectoryTheme.starGold),
                              const SizedBox(width: 4),
                              Text(
                                hospital.rating!.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: PremiumHospitalDirectoryTheme.text(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (hospital.address.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: PremiumHospitalDirectoryTheme.textSecondary(context).withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hospital.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: PremiumHospitalDirectoryTheme.textSecondary(context),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (visibleChips.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final chip in visibleChips)
                                _SpecializationChip(label: chip),
                              if (extraChips > 0) _SpecializationChip(label: '+$extraChips'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: PremiumHospitalDirectoryTheme.border(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  if (hasDoctors)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 16, color: PremiumHospitalDirectoryTheme.actionBlue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${hospital.doctorCount}+ Doctors',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: PremiumHospitalDirectoryTheme.textSecondary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasEmergency)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.emergency, size: 16, color: PremiumHospitalDirectoryTheme.emergencyRed),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Emergency ${hospital.emergencyLabel ?? '24/7'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: PremiumHospitalDirectoryTheme.emergencyRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (onBook != null && hospital.canOpenDetails)
                    Flexible(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onBook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PremiumHospitalDirectoryTheme.actionBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Book Appointment',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _HospitalThumbnail extends StatelessWidget {
  const _HospitalThumbnail({this.imageUri});

  final String? imageUri;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageUri != null
            ? Image.network(
                imageUri!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _assetFallback(),
              )
            : _assetFallback(),
      ),
    );
  }

  Widget _assetFallback() {
    return Image.asset(
      kHospitalBuildingAsset,
      fit: BoxFit.cover,
      alignment: const Alignment(0.3, 0),
      errorBuilder: (_, __, ___) => Container(
        color: PremiumHospitalDirectoryTheme.medicalBlue.withValues(alpha: 0.08),
        child: const Icon(Icons.local_hospital_rounded, color: PremiumHospitalDirectoryTheme.medicalBlue, size: 32),
      ),
    );
  }
}

class _SpecializationChip extends StatelessWidget {
  const _SpecializationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PremiumHospitalDirectoryTheme.actionBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumHospitalDirectoryTheme.actionBlue.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: PremiumHospitalDirectoryTheme.medicalBlue,
        ),
      ),
    );
  }
}

class PremiumHospitalDirectoryPagination extends StatelessWidget {
  const PremiumHospitalDirectoryPagination({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.onPageChanged,
    this.pageSize = 5,
  });

  final int currentPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    final totalPages = totalItems <= 0 ? 0 : (totalItems / pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    final start = currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, totalItems);
    final canPrev = currentPage > 0;
    final canNext = currentPage < totalPages - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: PremiumHospitalDirectoryTheme.white(context),
        border: Border(top: BorderSide(color: PremiumHospitalDirectoryTheme.border(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $totalItems hospitals',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: PremiumHospitalDirectoryTheme.textSecondary(context),
              ),
            ),
          ),
          _PageArrow(
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          ),
          ..._buildPageNumbers(context, totalPages),
          _PageArrow(
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context, int totalPages) {
    final pages = <int>[];
    if (totalPages <= 5) {
      pages.addAll(List.generate(totalPages, (i) => i));
    } else {
      final start = (currentPage - 1).clamp(0, totalPages - 3);
      final end = (start + 2).clamp(0, totalPages - 1);
      for (var i = start; i <= end; i++) {
        pages.add(i);
      }
    }

    return pages.map((p) {
      final active = p == currentPage;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: () => onPageChanged(p),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? PremiumHospitalDirectoryTheme.actionBlue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${p + 1}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : PremiumHospitalDirectoryTheme.textSecondary(context),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({required this.icon, required this.enabled, this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? PremiumHospitalDirectoryTheme.text(context)
                : PremiumHospitalDirectoryTheme.textSecondary(context).withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

enum HospitalDirectorySort { name, distance }

class PremiumHospitalFilterSheet extends StatefulWidget {
  const PremiumHospitalFilterSheet({
    super.key,
    required this.sort,
    required this.emergencyOnly,
    required this.showDistanceSort,
  });

  final HospitalDirectorySort sort;
  final bool emergencyOnly;
  final bool showDistanceSort;

  static Future<({HospitalDirectorySort sort, bool emergencyOnly})?> show(
    BuildContext context, {
    required HospitalDirectorySort sort,
    required bool emergencyOnly,
    required bool showDistanceSort,
  }) {
    return showModalBottomSheet<({HospitalDirectorySort sort, bool emergencyOnly})>(
      context: context,
      backgroundColor: PremiumHospitalDirectoryTheme.white(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PremiumHospitalFilterSheet(
        sort: sort,
        emergencyOnly: emergencyOnly,
        showDistanceSort: showDistanceSort,
      ),
    );
  }

  @override
  State<PremiumHospitalFilterSheet> createState() => _PremiumHospitalFilterSheetState();
}

class _PremiumHospitalFilterSheetState extends State<PremiumHospitalFilterSheet> {
  late HospitalDirectorySort _sort = widget.sort;
  late bool _emergencyOnly = widget.emergencyOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PremiumHospitalDirectoryTheme.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filter & Sort',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PremiumHospitalDirectoryTheme.text(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sort by',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PremiumHospitalDirectoryTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterOptionChip(
                label: 'Name',
                selected: _sort == HospitalDirectorySort.name,
                onTap: () => setState(() => _sort = HospitalDirectorySort.name),
              ),
              if (widget.showDistanceSort)
                _FilterOptionChip(
                  label: 'Distance',
                  selected: _sort == HospitalDirectorySort.distance,
                  onTap: () => setState(() => _sort = HospitalDirectorySort.distance),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Emergency hospitals only',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PremiumHospitalDirectoryTheme.text(context),
              ),
            ),
            value: _emergencyOnly,
            activeTrackColor: PremiumHospitalDirectoryTheme.healthcareTeal.withValues(alpha: 0.45),
            activeThumbColor: PremiumHospitalDirectoryTheme.healthcareTeal,
            onChanged: (v) => setState(() => _emergencyOnly = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, (sort: _sort, emergencyOnly: _emergencyOnly)),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumHospitalDirectoryTheme.medicalBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  const _FilterOptionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PremiumHospitalDirectoryTheme.medicalBlue : PremiumHospitalDirectoryTheme.background(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? PremiumHospitalDirectoryTheme.medicalBlue : PremiumHospitalDirectoryTheme.border(context),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : PremiumHospitalDirectoryTheme.text(context),
            ),
          ),
        ),
      ),
    );
  }
}
