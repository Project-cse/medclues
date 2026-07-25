import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/blood_bank_model.dart';
import 'blood_drop_icon.dart';

/// Single blood type — circle + teardrop + status label (detail view design).
class BloodTypeCircleTile extends StatelessWidget {
  const BloodTypeCircleTile({
    super.key,
    required this.type,
    required this.status,
    this.circleSize = 76,
  });

  final String type;
  final BloodStockStatus status;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    final ui = _uiFor(status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: ui.ring, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BloodDropIcon(label: '', status: status, size: circleSize * 0.38),
              Transform.translate(
                offset: Offset(0, -circleSize * 0.06),
                child: Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          status.displayLabel,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ui.statusText,
          ),
        ),
      ],
    );
  }

  static ({Color ring, Color statusText}) _uiFor(BloodStockStatus status) {
    return switch (status) {
      BloodStockStatus.available => (
          ring: const Color(0xFFFECACA),
          statusText: const Color(0xFF16A34A),
        ),
      BloodStockStatus.limited => (
          ring: const Color(0xFFFDE68A),
          statusText: const Color(0xFFEA580C),
        ),
      BloodStockStatus.unavailable => (
          ring: const Color(0xFFE2E8F0),
          statusText: const Color(0xFF94A3B8),
        ),
    };
  }
}

/// 4×2 grid of blood type circles.
class BloodAvailabilityGrid extends StatelessWidget {
  const BloodAvailabilityGrid({
    super.key,
    required this.bank,
    this.circleSize = 76,
  });

  final BloodBankModel bank;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    const types = BloodBankModel.bloodTypes;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: types
              .take(4)
              .map(
                (t) => BloodTypeCircleTile(
                  type: t,
                  status: bank.statusFor(t),
                  circleSize: circleSize,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: types
              .skip(4)
              .map(
                (t) => BloodTypeCircleTile(
                  type: t,
                  status: bank.statusFor(t),
                  circleSize: circleSize,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
