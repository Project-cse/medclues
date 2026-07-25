import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../constants/app_colors.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../routes/route_names.dart';

/// Help & Support — contact + replay app tutorial.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri)) {
      throw Exception('Could not open $uri');
    }
  }

  Future<void> _replayTour(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).resetForReplay();
    if (context.mounted) context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const supportEmail = AppConfig.supportEmail;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact MedClues support for appointments, billing, or technical issues.',
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _open(Uri(scheme: 'mailto', path: supportEmail)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    supportEmail,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.brandBlue),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.push(RouteNames.contactUs),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Open Contact Us form',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.brandBlue),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _open(Uri(scheme: 'tel', path: '108')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Emergency: 108',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.brandBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_lesson_rounded, color: AppColors.brandBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'App tutorial',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Replay the interactive walkthrough of hospitals, doctors, appointments, and records.',
                  style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _replayTour(context, ref),
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    label: Text(
                      'Take app tour',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
