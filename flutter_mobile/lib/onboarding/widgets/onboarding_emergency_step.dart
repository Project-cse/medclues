import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/emergency/models/emergency_contact_model.dart';
import '../../features/emergency/providers/emergency_provider.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/validators.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingEmergencyStep extends ConsumerStatefulWidget {
  const OnboardingEmergencyStep({super.key});

  @override
  ConsumerState<OnboardingEmergencyStep> createState() => _OnboardingEmergencyStepState();
}

class _OnboardingEmergencyStepState extends ConsumerState<OnboardingEmergencyStep> {
  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _skipIfAlreadySaved());
  }

  Future<void> _skipIfAlreadySaved() async {
    final has = await ref.read(onboardingServiceProvider).hasEmergencyContacts();
    if (!mounted || !has) return;
    await ref.read(emergencySettingsProvider.notifier).syncRemoteContactsFromApi();
    if (!mounted) return;
    await ref.read(onboardingProvider.notifier).completeEmergencyContact();
  }

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _error = null);

    final nameErr = Validators.emergencyContactName(_name.text, l10n);
    final phoneErr = Validators.emergencyContactPhone(_phone.text, l10n);
    if (nameErr != null || phoneErr != null) {
      setState(() => _error = nameErr ?? phoneErr);
      return;
    }
    if (_relation.text.trim().isEmpty) {
      setState(() => _error = l10n.emergencyRelationHint);
      return;
    }

    final contact = EmergencyContactModel(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      relation: _relation.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await ref.read(onboardingServiceProvider).addEmergencyContact(
            name: contact.name,
            phone: contact.phone,
            relation: contact.relation ?? '',
          );
      await ref.read(emergencySettingsProvider.notifier).upsertPrimaryContact(contact);
      if (!mounted) return;
      await ref.read(onboardingProvider.notifier).completeEmergencyContact();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7/8',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PremiumHealthcareTheme.secondaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingEmergencyContact,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: PremiumHealthcareTheme.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingEmergencyDesc,
                style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: PremiumHealthcareTheme.textSecondary(context)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingEmergencySecondLater,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: PremiumHealthcareTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.emergencyContact1,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(context)),
              ),
              const SizedBox(height: 12),
              _field(label: l10n.authFullName, controller: _name),
              const SizedBox(height: 14),
              _field(label: l10n.bookingRelationship, controller: _relation, hint: l10n.emergencyRelationHint),
              const SizedBox(height: 14),
              _field(label: l10n.authPhone, controller: _phone, keyboard: TextInputType.phone),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB91C1C))),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumHealthcareTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.onboardingSaveContinue, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: PremiumHealthcareTheme.text(context))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: PremiumHealthcareTheme.white(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: PremiumHealthcareTheme.border(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: PremiumHealthcareTheme.border(context))),
          ),
        ),
      ],
    );
  }
}
