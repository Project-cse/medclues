import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../providers/hospital_provider.dart';

/// Matches mobile/app/emergency.tsx (simplified).
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitals = ref.watch(hospitalsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Services')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Emergency Services',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text('Help is on the way', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          _callCard(context, 'Emergency', '112', filled: true),
          _callCard(context, 'Ambulance', '108', filled: false),
          const SizedBox(height: 24),
          Text('Nearby hospitals', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          hospitals.when(
            data: (list) => Column(
              children: list.take(6).map((h) {
                return Card(
                  child: ListTile(
                    title: Text(h.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(h.address),
                  ),
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text(e.toString()),
          ),
        ],
      ),
    );
  }

  Widget _callCard(BuildContext context, String label, String number, {required bool filled}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: filled ? AppColors.error : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => launchUrl(Uri.parse('tel:$number')),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.phone, color: filled ? Colors.white : AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$label — $number',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: filled ? Colors.white : AppColors.textPrimary,
                    ),
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
