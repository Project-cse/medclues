import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/profile_options.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingProfileStep extends ConsumerStatefulWidget {
  const OnboardingProfileStep({super.key});

  @override
  ConsumerState<OnboardingProfileStep> createState() => _OnboardingProfileStepState();
}

class _OnboardingProfileStepState extends ConsumerState<OnboardingProfileStep> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  bool _saving = false;
  bool _ready = false;
  String? _error;

  static final _inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
  static const _menuMaxHeight = 220.0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  void _applyPrefill(PatientModel? p, dynamic authUser) {
    final name = (p?.name.trim().isNotEmpty == true ? p!.name : authUser?.name) ?? '';
    _name.text = name;
    _email.text = p?.email ?? authUser?.email ?? '';
    _phone.text = ProfileOptions.sanitize(p?.phone) ?? ProfileOptions.sanitize(authUser?.phone) ?? '';
    _gender = ProfileOptions.normalizeGender(p?.gender);
    _bloodGroup = ProfileOptions.normalizeBloodGroup(p?.bloodGroup);
    _address.text = p?.address ?? '';
    final dobRaw = ProfileOptions.sanitize(p?.dob);
    if (dobRaw != null) {
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

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
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
  }

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
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _gender == null ||
        _bloodGroup == null ||
        _dob == null) {
      setState(() => _error = l10n.commonError);
      return;
    }

    setState(() => _saving = true);

    PatientModel profile;
    try {
      profile = await ref.read(patientProfileProvider.future);
    } catch (_) {
      final user = ref.read(authProvider).user;
      profile = PatientModel(
        id: user?.id ?? '',
        name: _name.text.trim(),
        email: user?.email ?? _email.text,
        phone: _phone.text.trim(),
      );
    }

    final updated = profile.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      bloodGroup: _bloodGroup,
      dob: DateFormat('yyyy-MM-dd').format(_dob!),
      address: _address.text.trim().isEmpty ? profile.address : _address.text.trim(),
    );

    // Advance to welcome screen immediately.
    await ref.read(onboardingProvider.notifier).completeProfile();

    try {
      await ref.read(onboardingServiceProvider).updateProfile(updated);
      ref.invalidate(patientProfileProvider);
    } catch (e) {
      // Profile saved on server may fail; user still continues — log for support.
      debugPrint('Onboarding profile sync: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final authUser = ref.read(authProvider).user;
    try {
      final p = await ref.read(patientProfileProvider.future);
      if (!mounted) return;
      final status = await ref.read(onboardingServiceProvider).fetchStatus();
      if (status.profileCompleted) {
        await ref.read(onboardingProvider.notifier).completeProfile();
        return;
      }
      setState(() {
        _applyPrefill(p, authUser);
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applyPrefill(null, authUser);
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      body: SafeArea(
        child: _ready
            ? _form()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _form() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingStep8of8, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.secondaryBlue)),
          const SizedBox(height: 8),
          Text(l10n.onboardingCompleteProfile, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(context))),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingCompleteProfileDesc,
            style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: PremiumHealthcareTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          _field('${l10n.authFullName} *', _name),
          const SizedBox(height: 12),
          _field(l10n.authEmail, _email, readOnly: true),
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
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.onboardingCompleteSetup, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType? keyboard, bool readOnly = false}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: _decoration(label),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('gender-$_gender'),
      initialValue: _gender,
      isExpanded: true,
      menuMaxHeight: _menuMaxHeight,
      decoration: _decoration('${context.l10n.authGender} *', hint: context.l10n.authGender),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Colors.white,
      items: ProfileOptions.genderItems
          .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2, style: GoogleFonts.inter(fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _bloodDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('blood-$_bloodGroup'),
      initialValue: _bloodGroup,
      isExpanded: true,
      menuMaxHeight: _menuMaxHeight,
      decoration: _decoration('${context.l10n.profileBloodGroup} *', hint: context.l10n.profileBloodGroup),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Colors.white,
      items: ProfileOptions.bloodGroups
          .map((g) => DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.inter(fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() => _bloodGroup = v),
    );
  }

  Widget _dobField() {
    final label = _dob == null ? context.l10n.authSelectDob : DateFormat('dd MMM yyyy').format(_dob!);
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
            color: _dob == null ? PremiumHealthcareTheme.textSecondary(context) : PremiumHealthcareTheme.text(context),
          ),
        ),
      ),
    );
  }
}
