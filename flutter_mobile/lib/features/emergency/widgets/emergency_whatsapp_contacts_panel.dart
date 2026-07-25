import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../emergency_constants.dart';
import '../models/emergency_contact_model.dart';
import '../providers/emergency_provider.dart';

/// WhatsApp messages + live location for saved relatives (no WhatsApp calls).
class EmergencyWhatsappContactsPanel extends ConsumerWidget {
  const EmergencyWhatsappContactsPanel({super.key});

  Future<void> _callRelative(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(emergencySettingsProvider).value;
    final contacts = settings?.savedContacts ?? [];
    if (contacts.isEmpty) return const SizedBox.shrink();

    final session = ref.watch(emergencySessionProvider);
    final notify = ref.read(emergencyNotificationProvider);
    final message = notify.buildAlertMessage(
      settings: settings!,
      location: session.location,
      extraNote: session.activeCase?.symptoms.isNotEmpty == true
          ? 'Symptoms: ${session.activeCase!.symptoms.join(', ')}'
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.chat, color: Color(0xFF25D366), size: 22),
              const SizedBox(width: 8),
              Text(
                'Notify Relatives',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: EmergencyConstants.emergencyRedDark,
                ),
              ),
            ],
          ),
        ),
        Text(
          'WhatsApp for messages & live location only',
          style: GoogleFonts.poppins(fontSize: 12, color: EmergencyConstants.emergencyText),
        ),
        const SizedBox(height: 8),
        ...contacts.map((c) => _ContactCard(
              contact: c,
              onWhatsApp: () => notify.openWhatsAppMessage(phone: c.phone, message: message),
              onPhoneCall: () => _callRelative(c.phone),
            )),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onWhatsApp,
    required this.onPhoneCall,
  });

  final EmergencyContactModel contact;
  final VoidCallback onWhatsApp;
  final VoidCallback onPhoneCall;

  @override
  Widget build(BuildContext context) {
    final subtitle = contact.relation?.isNotEmpty == true
        ? '${contact.relation} · ${contact.phone}'
        : contact.phone;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 13, color: EmergencyConstants.emergencyText),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _ActionBtn(
                label: 'WhatsApp — Message + Live Location',
                icon: Icons.message,
                color: const Color(0xFF25D366),
                onTap: onWhatsApp,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _ActionBtn(
                label: 'Phone Call',
                icon: Icons.phone,
                color: EmergencyConstants.emergencyRedDark,
                onTap: onPhoneCall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
