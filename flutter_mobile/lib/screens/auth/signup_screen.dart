import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../services/google_auth_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/validators.dart';
import '../../widgets/animations/healthcare_motion.dart';
import '../../widgets/animations/morph_action_button.dart';
import '../../widgets/animations/morphing_button.dart';
import '../../widgets/animations/validation_shake.dart';
import '../../widgets/animations/success_celebration.dart';
import '../../widgets/animations/wizard_progress_bar.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/brand_logo_mark.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/auth/login_screen_shell.dart';
import '../../widgets/auth/premium_login_theme.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../l10n/l10n_extension.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../constants/localized_form_options.dart';

/// Multi-step registration wizard — 4 steps with horizontal slide animations.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _terms = false;
  int _step = 0;
  MorphButtonState _btnState = MorphButtonState.idle;
  bool _googleLoading = false;
  bool _showSuccess = false;
  bool _shakeFields = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  bool _validateStep(int step) {
    final l10n = context.l10n;
    switch (step) {
      case 0:
        if (Validators.requiredField(_name.text, l10n.authFullName, l10n) != null) {
          AppSnackbar.show(context, l10n.authEnterFullNameError);
          return false;
        }
        if (_dob == null) {
          AppSnackbar.show(context, l10n.authSelectDobError);
          return false;
        }
        if (_gender == null) {
          AppSnackbar.show(context, l10n.authSelectGenderError);
          return false;
        }
        return true;
      case 1:
        if (Validators.email(_email.text, l10n) != null) {
          AppSnackbar.show(context, l10n.authEnterValidEmail);
          return false;
        }
        if (Validators.phone(_phone.text, l10n) != null) {
          final phoneError = Validators.phone(_phone.text, l10n);
          AppSnackbar.show(context, phoneError ?? l10n.validationPhoneInvalid);
          return false;
        }
        return true;
      case 2:
        if (Validators.password(_password.text, l10n) != null) {
          AppSnackbar.show(context, Validators.password(_password.text, l10n)!);
          return false;
        }
        if (Validators.confirmPassword(_confirm.text, _password.text, l10n) != null) {
          AppSnackbar.show(context, Validators.confirmPassword(_confirm.text, _password.text, l10n)!);
          return false;
        }
        if (!_terms) {
          AppSnackbar.show(context, l10n.authAcceptTermsError);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    _submit();
  }

  void _back() {
    if (_step == 0) {
      context.go(RouteNames.login);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _btnState = MorphButtonState.loading);
    try {
      await ref.read(authProvider.notifier).signup(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
            gender: _gender == null ? null : LocalizedFormOptions.genderToStorage(_gender!, context.l10n),
            dob: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
          );
      final state = ref.read(authProvider);
      if (!mounted) return;
      if (state.status == AuthStatus.authenticated) {
        setState(() {
          _btnState = MorphButtonState.success;
          _showSuccess = true;
          _step = 3;
        });
        await Future<void>.delayed(const Duration(milliseconds: 2200));
        if (mounted) context.go(RouteNames.dashboard);
      } else {
        setState(() => _btnState = MorphButtonState.idle);
        if (state.error != null) AppSnackbar.show(context, state.error!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _btnState = MorphButtonState.idle);
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final ok = await ref.read(authProvider.notifier).loginWithGoogle();
      if (!mounted || !ok) return;
      context.go(RouteNames.dashboard);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppException ? e.message : e.toString();
      if (msg != context.l10n.authSignInCancelled) AppSnackbar.show(context, msg);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stepLabels = [
      l10n.authStepPersonalInfo,
      l10n.authStepContactInfo,
      l10n.authStepSecurity,
      l10n.authStepSuccessLabel,
    ];
    return LoginScreenShell(
      child: Column(
        children: [
          const BrandLogoMark(),
          WizardProgressBar(step: _step, totalSteps: 4, labels: stepLabels),
          const SizedBox(height: 8),
          SizedBox(
            height: _showSuccess ? 380 : 420,
            child: PageTransitionSwitcher(
              duration: HealthcareMotion.standard,
              reverse: false,
              transitionBuilder: (child, animation, secondaryAnimation) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_step),
                child: _showSuccess
                    ? _successStep()
                    : ValidationShake(
                        shake: _shakeFields,
                        onComplete: () {
                          if (mounted) setState(() => _shakeFields = false);
                        },
                        child: _stepCard(_currentStepBody()),
                      ),
              ),
            ),
          ),
          if (!_showSuccess) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: Text(l10n.commonBack),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: MorphingButton(
                      label: _step == 2 ? l10n.authRegister : l10n.onboardingNext,
                      state: _btnState,
                      onPressed: _btnState == MorphButtonState.idle ? _next : null,
                    ),
                  ),
                ],
              ),
            ).authFormEnter(index: 4),
            if (_step == 0 && GoogleAuthService.setupHint == null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GoogleSignInButton(
                  loading: _googleLoading,
                  onPressed: _googleLoading ? null : _googleSignIn,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (!_showSuccess)
            GestureDetector(
              onTap: () => context.go(RouteNames.login),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: PremiumLoginTheme.textSecondary,
                  ),
                  children: [
                    TextSpan(text: l10n.authHaveAccount),
                    TextSpan(
                      text: l10n.authLoginLink,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: PremiumLoginTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ).authFormEnter(index: 5),
          if (!_showSuccess) const SizedBox(height: 16),
          if (!_showSuccess) const EmergencyHelpButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _currentStepBody() {
    switch (_step) {
      case 0:
        return _personalStep();
      case 1:
        return _contactStep();
      case 2:
        return _securityStep();
      default:
        return _personalStep();
    }
  }

  Widget _stepCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.loginCard,
      ),
      child: SingleChildScrollView(child: child),
    );
  }

  Widget _dobField() {
    final l10n = context.l10n;
    final hasDate = _dob != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.authDateOfBirth,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: PremiumLoginTheme.text,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(PremiumLoginTheme.fieldRadius),
            child: Container(
              height: PremiumLoginTheme.fieldHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PremiumLoginTheme.fieldRadius),
                border: Border.all(color: PremiumLoginTheme.inputBorder),
                color: PremiumLoginTheme.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: PremiumLoginTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasDate ? DateFormat('dd MMM yyyy').format(_dob!) : l10n.authSelectDobHint,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: hasDate ? FontWeight.w500 : FontWeight.w400,
                        color: hasDate ? PremiumLoginTheme.text : PremiumLoginTheme.placeholder,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: PremiumLoginTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _personalStep() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.authTellAboutYourself, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        AuthInput(
          label: l10n.authFullName,
          icon: Icons.person_outline,
          controller: _name,
          hintText: l10n.authEnterFullName,
          autofillHints: const [AutofillHints.name],
        ),
        _dobField(),
        DropdownButtonFormField<String>(
          value: _gender,
          dropdownColor: PremiumLoginTheme.white,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: PremiumLoginTheme.text,
          ),
          decoration: InputDecoration(
            labelText: l10n.authGender,
            labelStyle: GoogleFonts.inter(color: PremiumLoginTheme.textSecondary),
            filled: true,
            fillColor: PremiumLoginTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PremiumLoginTheme.fieldRadius),
              borderSide: const BorderSide(color: PremiumLoginTheme.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PremiumLoginTheme.fieldRadius),
              borderSide: const BorderSide(color: PremiumLoginTheme.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PremiumLoginTheme.fieldRadius),
              borderSide: const BorderSide(color: PremiumLoginTheme.accentBlue, width: 1.5),
            ),
          ),
          items: LocalizedFormOptions.genders(l10n)
              .map((gender) => DropdownMenuItem<String>(value: gender, child: Text(gender)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  Widget _contactStep() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.authHowReachYou, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        AuthInput(
          label: l10n.authEmail,
          icon: Icons.mail_outline,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          hintText: l10n.authEmailHint,
          autofillHints: const [AutofillHints.email],
        ),
        AuthInput(
          label: l10n.authPhone,
          icon: Icons.phone_outlined,
          controller: _phone,
          keyboardType: TextInputType.phone,
          hintText: l10n.authEnterPhoneHint,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
      ],
    );
  }

  Widget _securityStep() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.authSecureAccount, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        AuthInput(
          label: l10n.authPassword,
          icon: Icons.lock_outline,
          controller: _password,
          obscureText: true,
          hintText: l10n.authCreatePassword,
          autofillHints: const [AutofillHints.newPassword],
        ),
        AuthInput(
          label: l10n.authConfirmPassword,
          icon: Icons.lock_outline,
          controller: _confirm,
          obscureText: true,
          hintText: l10n.authConfirmPasswordHint,
          autofillHints: const [AutofillHints.newPassword],
        ),
        CheckboxListTile(
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          title: Text(l10n.authTermsAgree, style: GoogleFonts.poppins(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _successStep() {
    final l10n = context.l10n;
    return Center(
      child: SuccessCelebration(
        title: l10n.authSignupSuccess,
        subtitle: l10n.authWelcomeSubtitle,
      ),
    );
  }
}
