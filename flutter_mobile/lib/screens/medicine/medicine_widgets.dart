import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/medicine_model.dart';

IconData dosageFormIcon(String? placeholderType) {
  switch ((placeholderType ?? 'tablet').toLowerCase()) {
    case 'capsule':
      return Icons.medication_outlined;
    case 'syrup':
      return Icons.local_drink_outlined;
    case 'injection':
      return Icons.vaccines_outlined;
    case 'drops':
      return Icons.water_drop_outlined;
    case 'cream':
    case 'gel':
      return Icons.sanitizer_outlined;
    case 'inhaler':
      return Icons.air_outlined;
    default:
      return Icons.medication_liquid_outlined;
  }
}

class MedicinePlaceholder extends StatelessWidget {
  const MedicinePlaceholder({
    super.key,
    required this.placeholderType,
    this.size = 56,
  });

  final String placeholderType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = dosageFormIcon(placeholderType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFCCFBF1)],
        ),
      ),
      child: Icon(icon, color: AppColors.medcluesTeal, size: size * 0.45),
    );
  }
}

class MedicineResultCard extends StatelessWidget {
  const MedicineResultCard({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  final MedicineCard medicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicinePlaceholder(placeholderType: medicine.placeholderType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.medicineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((medicine.genericName ?? '').isNotEmpty &&
                        medicine.genericName != medicine.medicineName) ...[
                      const SizedBox(height: 2),
                      Text(
                        medicine.genericName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if ((medicine.manufacturer ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        medicine.manufacturer!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    if ((medicine.dosageForm ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          medicine.dosageForm!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.medcluesTeal,
                          ),
                        ),
                      ),
                    ],
                    if ((medicine.shortDescription ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        medicine.shortDescription!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
