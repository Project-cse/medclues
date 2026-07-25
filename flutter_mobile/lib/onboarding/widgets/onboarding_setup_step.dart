import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/profile_options.dart';
import '../../features/emergency/models/emergency_contact_model.dart';
import '../../features/emergency/providers/emergency_provider.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/validators.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../providers/onboarding_provider.dart';

/// Single, robust "Finish your setup" screen that replaces the two fragile
/// onboarding overlay steps (Emergency + Profile). It renders instantly from
/// cached data, validates everything once, and saves locally + in the
/// background so a slow/cold backend can never freeze the flow.
class OnboardingSetupStep extends ConsumerStatefulWidget {
  const OnboardingSetupStep({super.key});

  @override
  ConsumerState<OnboardingSetupStep> createState() => _OnboardingSetupStepState();
}

class _OnboardingSetupStepState extends ConsumerState<OnboardingSetupStep> {
  // Profile
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  bool _emailVerified = false;

  // Emergency contact
  final _ecName = TextEditingController();
  final _ecRelation = TextEditingController();
  final _ecPhone = TextEditingController();

  bool _saving = false;
  bool _loadingProfile = true;
  bool _forceEditProfile = false;
  String? _error;

  static final _inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  bool get _profileReady =>
      _name.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _gender != null &&
      _bloodGroup != null &&
      _dob != null;

  @override
  void initState() {
    super.initState();
    final authUser = ref.read(authProvider).user;
    final cached = ref.read(patientProfileProvider).valueOrNull;
    _applyPrefill(cached, authUser, force: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _applyPrefill(PatientModel? p, dynamic authUser, {bool force = false}) {
    void setText(TextEditingController c, String? value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return;
      if (force || c.text.trim().isEmpty) c.text = v;
    }

    setText(_name, p?.name.trim().isNotEmpty == true ? p!.name : authUser?.name);
    setText(_email, (p?.email.trim().isNotEmpty == true ? p!.email : authUser?.email));
    if (p?.emailVerified == true) _emailVerified = true;
    setText(
      _phone,
      ProfileOptions.sanitize(p?.phone) ?? ProfileOptions.sanitize(authUser?.phone),
    );

    final g = ProfileOptions.normalizeGender(p?.gender);
    if (g != null && (force || _gender == null)) _gender = g;
    final b = ProfileOptions.normalizeBloodGroup(p?.bloodGroup);
    if (b != null && (force || _bloodGroup == null)) _bloodGroup = b;
    if (p?.address != null && p!.address!.trim().isNotEmpty && (force || _address.text.trim().isEmpty)) {
      _address.text = p.address!;
    }
    final dobRaw = ProfileOptions.sanitize(p?.dob);
    if (dobRaw != null && (force || _dob == null)) {
      _dob = DateTime.tryParse(dobRaw) ?? _tryParseDob(dobRaw);
    }
  }

  DateTime? _tryParseDob(String raw) {
    for (final pattern in ['yyyy-MM-dd', 'dd-MM-yyyy', 'dd/MM/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  /// Pull signup details from the server and fill every field.
  Future<void> _bootstrap() async {
    setState(() => _loadingProfile = true);
    try {
      final p = await ref.refresh(patientProfileProvider.future).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _applyPrefill(p, ref.read(authProvider).user, force: true);
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    _ecName.dispose();
    _ecRelation.dispose();
    _ecPhone.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: PremiumHealthcareTheme.white(context),
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: PremiumHealthcareTheme.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: PremiumHealthcareTheme.primaryBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: PremiumHealthcareTheme.text(context),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _error = null);

    // 1. Profile validation
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _gender == null ||
        _bloodGroup == null ||
        _dob == null) {
      setState(() => _error = 'Please complete all required profile fields (marked *).');
      return;
    }

    // 2. Emergency contact validation
    final nameErr = Validators.emergencyContactName(_ecName.text, l10n);
    final phoneErr = Validators.emergencyContactPhone(_ecPhone.text, l10n);
    if (nameErr != null || phoneErr != null) {
      setState(() => _error = nameErr ?? phoneErr);
      return;
    }
    if (_ecRelation.text.trim().isEmpty) {
      setState(() => _error = 'Please add the emergency contact\'s relationship.');
      return;
    }

    setState(() => _saving = true);

    final user = ref.read(authProvider).user;
    final base = ref.read(patientProfileProvider).valueOrNull ??
        PatientModel(
          id: user?.id ?? '',
          name: _name.text.trim(),
          email: user?.email ?? _email.text,
          phone: _phone.text.trim(),
        );
    final updatedProfile = base.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      bloodGroup: _bloodGroup,
      dob: DateFormat('yyyy-MM-dd').format(_dob!),
      address: _address.text.trim().isEmpty ? base.address : _address.text.trim(),
    );

    final contact = EmergencyContactModel(
      name: _ecName.text.trim(),
      phone: _ecPhone.text.trim(),
      relation: _ecRelation.text.trim(),
    );

    final service = ref.read(onboardingServiceProvider);
    final emergencyNotifier = ref.read(emergencySettingsProvider.notifier);
    final router = GoRouter.of(context);

    // Finish UI immediately — never wait on storage / API (was hanging the spinner).
    ref.read(onboardingProvider.notifier).finishOnboarding();
    router.go(RouteNames.dashboard);

    // Background sync only (fire-and-forget).
    unawaited(emergencyNotifier.upsertPrimaryContact(contact).catchError((_) {}));
    unawaited(service
        .addEmergencyContact(
          name: contact.name,
          phone: contact.phone,
          relation: contact.relation ?? '',
        )
        .catchError((_) {}));
    unawaited(service.updateProfile(updatedProfile).then((_) {
      ref.invalidate(patientProfileProvider);
    }).catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final verifyOnly = _profileReady && !_forceEditProfile;

    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required setup',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PremiumHealthcareTheme.secondaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verifyOnly ? 'Confirm your details' : 'Complete your profile',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: PremiumHealthcareTheme.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verifyOnly
                    ? 'We loaded your signup details below. Confirm them and add one emergency contact to continue.'
                    : 'Review your details and add one emergency contact. This step is required before you can use the app.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: PremiumHealthcareTheme.textSecondary(context),
                ),
              ),
              if (_loadingProfile) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 22),

              _sectionTitle(verifyOnly ? 'Your profile (from signup)' : 'Your Profile'),
              const SizedBox(height: 12),
              if (verifyOnly) ...[
                _verifyCard(context),
              ] else ...[
                _field('${l10n.authFullName} *', _name),
                const SizedBox(height: 12),
                _emailField(),
                const SizedBox(height: 12),
                _field('${l10n.authPhone} *', _phone, keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _genderDropdown(),
                const SizedBox(height: 12),
                _dobField(),
                const SizedBox(height: 12),
                _bloodDropdown(),
                const SizedBox(height: 12),
                _field(l10n.profileAddress, _address),
              ],

              const SizedBox(height: 26),
              _sectionTitle('Emergency Contact'),
              const SizedBox(height: 4),
              Text(
                'One person we can alert in an emergency. Required.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: PremiumHealthcareTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              _field('${l10n.authFullName} *', _ecName),
              const SizedBox(height: 12),
              _field(
                '${l10n.bookingRelationship} *',
                _ecRelation,
                hint: l10n.emergencyRelationHint,
              ),
              const SizedBox(height: 12),
              _field('${l10n.authPhone} *', _ecPhone, keyboard: TextInputType.phone),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB91C1C)),
                  ),
                ),
              ],

              const SizedBox(height: 24),
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
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          verifyOnly ? 'Confirm & continue' : l10n.onboardingCompleteSetup,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verifyCard(BuildContext context) {
    final genderLabel = ProfileOptions.genderItems
        .where((e) => e.$1 == _gender)
        .map((e) => e.$2)
        .firstOrNull;
    final dobLabel = _dob == null ? '—' : DateFormat('dd MMM yyyy').format(_dob!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumHealthcareTheme.white(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumHealthcareTheme.border(context)),
      ),
      child: Column(
        children: [
          _verifyRow('Full name', _name.text),
          _verifyRow('Email', _email.text, trailing: _emailVerified ? const _VerifiedChip() : null),
          _verifyRow('Phone', _phone.text),
          _verifyRow('Gender', genderLabel ?? _gender ?? '—'),
          _verifyRow('Date of birth', dobLabel),
          _verifyRow('Blood group', _bloodGroup ?? '—'),
          if (_address.text.trim().isNotEmpty) _verifyRow('Address', _address.text, last: true),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _forceEditProfile = true),
              child: Text(
                'Edit profile details',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyRow(String label, String value, {Widget? trailing, bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PremiumHealthcareTheme.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PremiumHealthcareTheme.text(context),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: PremiumHealthcareTheme.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PremiumHealthcareTheme.text(context),
            ),
          ),
        ],
      );

  Widget _emailField() {
    return Row(
      children: [
        Expanded(child: _field(context.l10n.authEmail, _email, readOnly: true)),
        if (_emailVerified) ...[
          const SizedBox(width: 10),
          const _VerifiedChip(),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType? keyboard,
    bool readOnly = false,
    String? hint,
  }) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: _decoration(label, hint: hint),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('gender-$_gender'),
      value: _gender,
      isExpanded: true,
      menuMaxHeight: 220,
      decoration: _decoration('${context.l10n.authGender} *', hint: context.l10n.authGender),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: PremiumHealthcareTheme.white(context),
      items: ProfileOptions.genderItems
          .map(
            (e) => DropdownMenuItem(
              value: e.$1,
              child: Text(
                e.$2,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: PremiumHealthcareTheme.text(context),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _bloodDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('blood-$_bloodGroup'),
      value: _bloodGroup,
      isExpanded: true,
      menuMaxHeight: 220,
      decoration: _decoration(
        '${context.l10n.profileBloodGroup} *',
        hint: context.l10n.profileBloodGroup,
      ),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: PremiumHealthcareTheme.white(context),
      items: ProfileOptions.bloodGroups
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(
                g,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: PremiumHealthcareTheme.text(context),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _bloodGroup = v),
    );
  }

  Widget _dobField() {
    final label =
        _dob == null ? context.l10n.authSelectDob : DateFormat('dd MMM yyyy').format(_dob!);
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration('${context.l10n.authDateOfBirth} *').copyWith(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _dob == null
                ? PremiumHealthcareTheme.textSecondary(context)
                : PremiumHealthcareTheme.text(context),
          ),
        ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}
