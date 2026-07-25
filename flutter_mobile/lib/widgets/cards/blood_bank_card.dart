import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/blood_bank_model.dart';
import '../../utils/theme_context.dart';
import '../blood/blood_drop_icon.dart';

/// List teaser — tap opens full availability detail screen.
class BloodBankCard extends StatelessWidget {
  const BloodBankCard({super.key, required this.bank});

  final BloodBankModel bank;

  void _openDetail(BuildContext context) {
    context.push('/blood-banks/${bank.id}', extra: bank);
  }

  @override
  Widget build(BuildContext context) {
    final location = bank.city.isNotEmpty ? bank.city : bank.address;
    final availableCount =
        BloodBankModel.bloodTypes.where((t) => bank.statusFor(t) == BloodStockStatus.available).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(context),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: context.cardDecoration(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.primaryText,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              location,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: context.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (bank.partner) _partnerChip(context),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: context.secondaryText, size: 22),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ...BloodBankModel.bloodTypes.take(4).map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: BloodDropIcon(
                          label: t,
                          status: bank.statusFor(t),
                          size: 32,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$availableCount types available',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap to view full stock',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.hintText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _partnerChip(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Partner',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: context.isDark ? context.cs.primary : const Color(0xFF4F46E5),
        ),
      ),
    );
  }
}
