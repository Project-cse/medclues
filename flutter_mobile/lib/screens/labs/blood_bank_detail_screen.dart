import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/blood_bank_model.dart';
import '../../utils/theme_context.dart';
import '../../widgets/blood/blood_type_circle_tile.dart';

/// Full blood stock view after tapping a bank from the list.
class BloodBankDetailScreen extends StatelessWidget {
  const BloodBankDetailScreen({super.key, required this.bank});

  final BloodBankModel bank;

  @override
  Widget build(BuildContext context) {
    final location = bank.city.isNotEmpty ? bank.city : bank.address;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blood Availability',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: context.cardDecoration(radius: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: context.secondaryText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: context.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (bank.partner) _partnerChip(context),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
              decoration: context.cardDecoration(radius: 24),
              child: BloodAvailabilityGrid(bank: bank),
            ),
            if (bank.phone != null && bank.phone!.isNotEmpty) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:${bank.phone}')),
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: Text(
                  'Call ${bank.phone}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _partnerChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.isDark ? context.borderColor : const Color(0xFFC7D2FE),
        ),
      ),
      child: Text(
        'Partner',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: context.isDark ? context.cs.primary : const Color(0xFF4F46E5),
        ),
      ),
    );
  }
}
