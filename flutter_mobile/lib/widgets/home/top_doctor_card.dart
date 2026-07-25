import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../models/doctor_model.dart';
import '../common/avatar_image.dart';

class TopDoctorCard extends StatelessWidget {
  const TopDoctorCard({super.key, required this.doctor, required this.onTap});

  final DoctorModel doctor;
  final VoidCallback onTap;

  static const double cardWidth = 120;

  @override
  Widget build(BuildContext context) {
    final displayName = doctor.name.replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.specCircleFill, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.specCircleFill, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: AvatarImage(uri: doctor.imageUrl, size: 66),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: doctor.isOnline
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        )
                      : Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
            ),
            Text(
              doctor.specialization,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: context.secondaryText),
            ),
            if (doctor.hasRating) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.starBright),
                  const SizedBox(width: 4),
                  Text(
                    doctor.displayRatingText!,
                    style: GoogleFonts.poppins(fontSize: 11, color: context.secondaryText),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
