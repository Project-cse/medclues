import 'package:flutter/material.dart';
import 'package:medichain_mobile/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/localized_form_options.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/patient_booking_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_state_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/input_formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/healthcare/premium_booking_flow_widgets.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../../widgets/healthcare/premium_patient_form_field.dart';

/// Patient selection + details — premium booking flow (Screen 1).
class BookingPatientSelectorScreen extends ConsumerStatefulWidget {
  const BookingPatientSelectorScreen({super.key, required this.doctorId, this.preferOnline = false});

  final String doctorId;
  final bool preferOnline;

  @override
  ConsumerState<BookingPatientSelectorScreen> createState() => _BookingPatientSelectorScreenState();
}

class _BookingPatientSelectorScreenState extends ConsumerState<BookingPatientSelectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  String _gender = '';
  String _relationship = '';
  bool _showPatientForm = false;
  bool _formValid = false;

  void _ensureLocalizedDefaults(AppLocalizations l10n) {
    if (_gender.isEmpty) _gender = LocalizedFormOptions.genders(l10n).first;
    if (_relationship.isEmpty) _relationship = LocalizedFormOptions.relationships(l10n).first;
  }

  @override
  void initState() {
    super.initState();
    final mode = widget.preferOnline ? 'online' : 'offline';
    Future.microtask(() => prefetchDoctorSchedule(ref, widget.doctorId, mode: mode));
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    super.dispose();
  }

  String get _bookingPath {
    final q = widget.preferOnline ? '?visit=online' : '';
    return '/booking/${widget.doctorId}$q';
  }

  void _bookForMe() {
    final l10n = context.l10n;
    final auth = ref.read(authProvider).user;
    final profile = ref.read(patientProfileProvider).valueOrNull;
    final name = profile?.name ?? auth?.name ?? '';
    if (name.isEmpty) {
      AppSnackbar.show(context, l10n.bookingCompleteProfile);
      return;
    }
    String? age;
    final dob = profile?.dob;
    if (dob != null && dob.isNotEmpty) {
      final parsed = DateTime.tryParse(dob);
      if (parsed != null) {
        final now = DateTime.now();
        var years = now.year - parsed.year;
        if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
          years--;
        }
        age = '$years';
      }
    }
    final patient = PatientBookingInfo.self(
      name: name,
      phone: profile?.phone ?? auth?.phone,
      gender: profile?.gender,
      age: age,
    );
    ref.read(bookingPatientProvider.notifier).state = patient;
    context.push(_bookingPath);
  }

  void _revalidateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_formValid != valid) setState(() => _formValid = valid);
  }

  Future<void> _pickAge() async {
    final l10n = context.l10n;
    final current = int.tryParse(_age.text.trim()) ?? 25;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        var selected = current.clamp(0, 120);
        return SafeArea(
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.bookingSelectAge,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 44,
                    perspective: 0.003,
                    diameterRatio: 1.4,
                    onSelectedItemChanged: (i) => selected = i,
                    controller: FixedExtentScrollController(initialItem: selected),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 121,
                      builder: (_, i) => Center(
                        child: Text(
                          '$i',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: PremiumContinueButton(
                    label: l10n.commonDone,
                    onPressed: () => Navigator.pop(ctx, selected),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      _age.text = '$picked';
      _revalidateForm();
    }
  }

  void _bookForOthers() {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final patient = PatientBookingInfo(
      name: Validators.trimText(_name.text),
      age: Validators.trimText(_age.text),
      gender: LocalizedFormOptions.genderToStorage(_gender, l10n),
      phone: Validators.trimText(_phone.text),
      relationship: LocalizedFormOptions.relationshipToStorage(_relationship, l10n),
      isSelf: false,
    );
    ref.read(bookingPatientProvider.notifier).state = patient;
    context.push(_bookingPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _ensureLocalizedDefaults(l10n);
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final doctorName = doctorAsync.valueOrNull?.name ?? l10n.doctorProfile;

    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      body: Stack(
        children: [
          Column(
            children: [
              PremiumBookingHeroHeader(
                doctorName: doctorName,
                onClose: () => context.pop(),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          Positioned(
            top: 130 + MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: PremiumHealthcareTheme.white(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(PremiumHealthcareTheme.sheetTopRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: doctorAsync.isLoading
                  ? const Center(child: AppLoader())
                  : _showPatientForm
                      ? _PatientDetailsForm(
                          l10n: l10n,
                          formKey: _formKey,
                          name: _name,
                          age: _age,
                          phone: _phone,
                          gender: _gender,
                          relationship: _relationship,
                          canContinue: _formValid,
                          onGenderChanged: (v) {
                            setState(() => _gender = v);
                            _revalidateForm();
                          },
                          onRelationshipChanged: (v) {
                            setState(() => _relationship = v);
                            _revalidateForm();
                          },
                          onFieldChanged: _revalidateForm,
                          onPickAge: _pickAge,
                          onBack: () => setState(() => _showPatientForm = false),
                          onContinue: _bookForOthers,
                        )
                      : _WhoIsItFor(
                          l10n: l10n,
                          onMyself: _bookForMe,
                          onSomeoneElse: () => setState(() => _showPatientForm = true),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhoIsItFor extends StatelessWidget {
  const _WhoIsItFor({required this.l10n, required this.onMyself, required this.onSomeoneElse});

  final AppLocalizations l10n;
  final VoidCallback onMyself;
  final VoidCallback onSomeoneElse;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        28,
        PremiumHealthcareTheme.horizontalPadding,
        32,
      ),
      child: Column(
        children: [
          PremiumSectionTitleRow(
            title: l10n.bookingWhoIsItFor,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bookingSelectOption,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: PremiumHealthcareTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 28),
          PremiumWhoOptionCard(
            icon: Icons.person_rounded,
            title: l10n.bookingForMyself,
            subtitle: l10n.bookingForMyselfSubtitle,
            accentColor: PremiumHealthcareTheme.primaryBlue,
            onTap: onMyself,
          ),
          const SizedBox(height: 14),
          PremiumWhoOptionCard(
            icon: Icons.people_outline_rounded,
            title: l10n.bookingForOthers,
            subtitle: l10n.bookingForOthersSubtitle,
            accentColor: PremiumHealthcareTheme.secondaryBlue,
            onTap: onSomeoneElse,
          ),
        ],
      ),
    );
  }
}

class _PatientDetailsForm extends StatelessWidget {
  const _PatientDetailsForm({
    required this.l10n,
    required this.formKey,
    required this.name,
    required this.age,
    required this.phone,
    required this.gender,
    required this.relationship,
    required this.canContinue,
    required this.onGenderChanged,
    required this.onRelationshipChanged,
    required this.onFieldChanged,
    required this.onPickAge,
    required this.onBack,
    required this.onContinue,
  });

  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController age;
  final TextEditingController phone;
  final String gender;
  final String relationship;
  final bool canContinue;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onRelationshipChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onPickAge;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                PremiumHealthcareTheme.horizontalPadding,
                24,
                PremiumHealthcareTheme.horizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PremiumFlowBackButton(onTap: onBack),
                  const SizedBox(height: 20),
                  PremiumSectionTitleRow(
                    title: l10n.bookingPatientDetails,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 28),
                  PremiumPatientFormField(
                    label: l10n.bookingPatientName,
                    controller: name,
                    icon: Icons.person_outline_rounded,
                    validator: (v) => Validators.patientName(v, l10n),
                    inputFormatters: InputFormatters.name,
                    onChanged: (_) => onFieldChanged(),
                  ),
                  const SizedBox(height: 20),
                  PremiumPatientFormField(
                    label: l10n.bookingAge,
                    controller: age,
                    icon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: onPickAge,
                    validator: (v) => Validators.age(v, l10n),
                  ),
                  const SizedBox(height: 20),
                  PremiumPatientDropdownField(
                    label: l10n.authGender,
                    value: gender,
                    items: LocalizedFormOptions.genders(l10n),
                    icon: Icons.wc_outlined,
                    onChanged: onGenderChanged,
                  ),
                  const SizedBox(height: 20),
                  PremiumPatientFormField(
                    label: l10n.bookingContactNumber,
                    controller: phone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => Validators.indianPhone(v, l10n),
                    inputFormatters: InputFormatters.phone,
                    onChanged: (_) => onFieldChanged(),
                  ),
                  const SizedBox(height: 20),
                  PremiumPatientDropdownField(
                    label: l10n.bookingRelationship,
                    value: relationship,
                    items: LocalizedFormOptions.relationships(l10n),
                    icon: Icons.family_restroom_outlined,
                    onChanged: onRelationshipChanged,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PremiumHealthcareTheme.horizontalPadding,
              8,
              PremiumHealthcareTheme.horizontalPadding,
              24,
            ),
            child: PremiumContinueButton(
              label: l10n.commonContinue,
              onPressed: canContinue ? onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
