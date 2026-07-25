import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../widgets/brand/medclues_logo_image.dart';

/// Corporate "About" page for MedClues — branded hero, mission, feature grid
/// and trust highlights. Fully theme-aware (light + dark).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = <(IconData, String, String)>[
    (Icons.local_hospital_outlined, 'Verified Hospitals', 'Book with trusted, partnered hospitals near you.'),
    (Icons.medical_services_outlined, 'Expert Doctors', 'Consult specialists in person or over video.'),
    (Icons.videocam_outlined, 'Video Consults', 'Secure, high-quality online consultations.'),
    (Icons.folder_shared_outlined, 'Health Records', 'Keep your reports safe and always handy.'),
    (Icons.emergency_outlined, 'Emergency Help', 'One-tap SOS with your trusted contacts.'),
    (Icons.payments_outlined, 'Easy Payments', 'Transparent billing and payment history.'),
  ];

  static const _values = <(IconData, String, String)>[
    (Icons.verified_user_outlined, 'Secure & Private', 'Your medical data is encrypted and protected.'),
    (Icons.bolt_outlined, 'Fast & Reliable', 'Quick bookings and dependable service.'),
    (Icons.favorite_outline, 'Patient-First', 'Every feature is designed around your care.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _missionCard(context),
                const SizedBox(height: 24),
                _sectionTitle(context, 'What We Offer'),
                const SizedBox(height: 12),
                _featureGrid(context),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Why MedClues'),
                const SizedBox(height: 12),
                ..._values.map((v) => _valueRow(context, v)),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} MedClues. All rights reserved.',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.medcluesNavy, AppColors.medcluesTeal],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: const MedcluesLogoImage(size: MedcluesLogoSize.auth),
          ),
          const SizedBox(height: 18),
          Text(
            'About MedClues',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Revolutionizing healthcare through modern technology and patient-centric care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13.5, height: 1.5, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _missionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.medcluesTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_outlined, color: AppColors.medcluesTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Our Mission', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: context.primaryText)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'MedClues transforms healthcare through innovation and technology. We help patients book appointments, access medical records, and connect with trusted doctors and hospitals — securely and conveniently, all in one platform.',
            style: GoogleFonts.poppins(fontSize: 13.5, height: 1.6, color: context.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: _features.map((f) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.$1, color: AppColors.brandBlue, size: 20),
              ),
              const Spacer(),
              Text(f.$2, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.primaryText)),
              const SizedBox(height: 4),
              Text(
                f.$3,
                style: GoogleFonts.poppins(fontSize: 11, height: 1.35, color: context.secondaryText),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _valueRow(BuildContext context, (IconData, String, String) v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.medcluesTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(v.$1, color: AppColors.medcluesTeal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.$2, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: context.primaryText)),
                  const SizedBox(height: 2),
                  Text(v.$3, style: GoogleFonts.poppins(fontSize: 12, height: 1.4, color: context.secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: context.primaryText));
  }
}
