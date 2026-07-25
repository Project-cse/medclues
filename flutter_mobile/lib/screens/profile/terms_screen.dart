import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Terms & Conditions for MedClues patient app.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = <_TermsSection>[
    _TermsSection(
      '1. Acceptance',
      'By using MedClues, you agree to these Terms & Conditions. If you do not agree, please do not use the app.',
    ),
    _TermsSection(
      '2. Services',
      'MedClues helps you discover healthcare providers, book appointments, manage records, and access related health services. Availability may vary by location and provider.',
    ),
    _TermsSection(
      '3. User Responsibilities',
      'You must provide accurate information, keep your login credentials secure, and use the app only for lawful personal healthcare purposes.',
    ),
    _TermsSection(
      '4. Appointments & Payments',
      'Appointment confirmations depend on doctor and hospital availability. Online consultation fees are processed via our payment partners. In-clinic fees may be payable at the hospital.',
    ),
    _TermsSection(
      '5. Medical Disclaimer',
      'MedClues is a healthcare platform, not a medical provider. Content and AI-assisted features are informational only and do not replace professional medical advice.',
    ),
    _TermsSection(
      '6. Privacy',
      'We collect and process personal data as described in our Privacy Policy to deliver and improve our services.',
    ),
    _TermsSection(
      '7. Changes',
      'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the updated terms.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Terms & Conditions',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: June 2026',
            style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (final s in _sections) ...[
            Text(
              s.title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              s.body,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.title, this.body);
  final String title;
  final String body;
}
