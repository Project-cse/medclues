import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/theme_context.dart';
import '../../widgets/common/app_snackbar.dart';

/// Corporate "Contact Us" page — support details + form sent via API
/// (mailto fallback if the API / email provider is unavailable).
class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  static const _supportEmail = AppConfig.supportEmail;
  static const _supportPhone = AppConfig.supportPhone;
  static const _supportAddress = 'MedClues HQ, Hyderabad, Telangana, India';
  static const _supportHours = 'Mon – Sat, 9:00 AM – 8:00 PM IST';

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _prefilled = false;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _prefill() {
    if (_prefilled) return;
    final profile = ref.read(patientProfileProvider).valueOrNull;
    final auth = ref.read(authProvider).user;
    _name.text = profile?.name ?? auth?.name ?? '';
    _email.text = profile?.email ?? auth?.email ?? '';
    _prefilled = true;
  }

  Future<void> _mailtoFallback({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final body = 'Name: $name\nEmail: $email\n\n$message';
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppSnackbar.show(
        context,
        'Could not open your email app. Email us at $_supportEmail',
      );
    }
  }

  Future<void> _send() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();

    if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
      AppSnackbar.show(context, 'Please fill in all fields.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnackbar.show(context, 'Please enter a valid email address.');
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(patientServiceProvider).sendContactMessage(
            name: name,
            email: email,
            subject: subject,
            message: message,
          );
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      AppSnackbar.show(context, 'Message sent. We will get back to you soon.');
    } catch (_) {
      // API or email provider unavailable — open device mail app
      await _mailtoFallback(
        name: name,
        email: email,
        subject: subject,
        message: message,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _contactTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: _supportEmail,
                  onTap: () => launchUrl(
                    Uri(scheme: 'mailto', path: _supportEmail),
                  ),
                ),
                _contactTile(
                  icon: Icons.call_outlined,
                  title: 'Phone',
                  value: _supportPhone,
                  onTap: () => launchUrl(
                    Uri(
                      scheme: 'tel',
                      path: _supportPhone.replaceAll(' ', ''),
                    ),
                  ),
                ),
                _contactTile(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: _supportAddress,
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_supportAddress)}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _contactTile(
                  icon: Icons.schedule_outlined,
                  title: 'Support Hours',
                  value: _supportHours,
                ),
                const SizedBox(height: 24),
                Text(
                  'Send us a message',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We usually respond within 24 hours.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: context.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                _formCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.medcluesNavy, AppColors.medcluesTeal],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "We're here to help",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Questions about appointments, billing, or the app? Reach our support team any time.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.brandBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: context.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: context.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        children: [
          _field(_name, 'Full Name', Icons.person_outline),
          const SizedBox(height: 12),
          _field(
            _email,
            'Email Address',
            Icons.mail_outline,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _field(_subject, 'Subject', Icons.subject_rounded),
          const SizedBox(height: 12),
          _field(_message, 'Message', Icons.message_outlined, maxLines: 4),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _sending ? 'Sending…' : 'Send Message',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medcluesNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: context.primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: context.secondaryText, fontSize: 13),
        prefixIcon: maxLines == 1 ? Icon(icon, size: 20, color: context.secondaryText) : null,
        alignLabelWithHint: true,
        filled: true,
        fillColor: context.isDark ? context.cardColor : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.medcluesTeal, width: 1.5),
        ),
      ),
    );
  }
}
