import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../models/doctor_model.dart';
import '../../utils/image_url_helper.dart';
import '../animations/healthcare_motion.dart';
import '../common/avatar_image.dart';
import '../common/doctor_status_badge.dart';

/// Matches mobile/components/cards/DoctorListCard.tsx
class DoctorCard extends StatefulWidget {
  const DoctorCard({super.key, required this.doctor, this.index = 0, this.onBook});

  final DoctorModel doctor;
  final int index;
  final VoidCallback? onBook;

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.doctorBorderColors[widget.index % AppColors.doctorBorderColors.length];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push('/doctors/${widget.doctor.id}'),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(color: borderColor, child: const SizedBox(width: 4)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: AvatarImage(uri: resolveImageUrl(widget.doctor.imageUrl), size: 56),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.doctor.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: context.primaryText,
                                  ),
                                ),
                                Text(
                                  widget.doctor.specialization,
                                  style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                                ),
                                if (widget.doctor.experienceLabel != null &&
                                    widget.doctor.experienceLabel!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.highlightBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.doctor.experienceLabel!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.doctor.hasRating)
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 12, color: AppColors.starBright),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.doctor.displayRatingText!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: context.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: DoctorStatusBadge(doctor: widget.doctor, compact: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).searchResultEnter(widget.index);
  }
}
