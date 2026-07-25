import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../services/google_auth_service.dart';
import '../../services/phone_auth_service.dart';
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
import '../../constants/profile_options.dart';

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
  String? _bloodGroup;
  DateTime? _dob;
  bool _terms = false;
  int _step = 0;
  MorphButtonState _btnState = MorphButtonState.idle;
  bool _googleLoading = false;
  bool _showSuccess = false;
  bool _shakeFields = false;

  final _phoneAuth = PhoneAuthService();
  bool _phoneVerified = false;
  bool _sendingOtp = false;
  String? _phoneIdToken;
  String? _verifiedPhone;

  bool _emailVerified = false;
  bool _sendingEmailOtp = false;
  String? _verifiedEmail;

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onPhoneChanged);
    _password.addListener(_onPasswordChanged);
    _email.addListener(_onEmailChanged);
  }

  /// Editing the email after verifying invalidates the proof.
  void _onEmailChanged() {
    if (_emailVerified && _email.text.trim().toLowerCase() != _verifiedEmail) {
      setState(() {
        _emailVerified = false;
        _verifiedEmail = null;
      });
    }
  }

  /// Rebuild so the live password-requirements checklist updates as the user types.
  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  /// Editing the phone after verifying invalidates the proof.
  void _onPhoneChanged() {
    if (_phoneVerified && _phone.text.trim() != _verifiedPhone) {
      setState(() {
        _phoneVerified = false;
        _phoneIdToken = null;
        _verifiedPhone = null;
      });
    }
  }

  @override
  void dispose() {
    _phone.removeListener(_onPhoneChanged);
    _password.removeListener(_onPasswordChanged);
    _email.removeListener(_onEmailChanged);
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
        if (_bloodGroup == null) {
          AppSnackbar.show(context, 'Please select your blood group');
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
        // Email must be verified here before continuing.
        if (!_emailVerified) {
          AppSnackbar.show(context, 'Please verify your email to continue.');
          return false;
        }
        // Phone OTP verification is optional — users may verify now or later.
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
            bloodGroup: _bloodGroup,
            phoneIdToken: _phoneIdToken,
          );
      final state = ref.read(authProvider);
      if (!mounted) return;
      if (state.status == AuthStatus.authenticated) {
        if (!mounted) return;
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

  /// Verifies the email entered on the contact step via a 6-digit OTP — before
  /// the account is created (uses the public pre-signup endpoints).
  Future<void> _verifyEmail() async {
    final l10n = context.l10n;
    final emailError = Validators.email(_email.text, l10n);
    if (emailError != null) {
      AppSnackbar.show(context, l10n.authEnterValidEmail);
      return;
    }
    setState(() => _sendingEmailOtp = true);
    String? devOtp;
    try {
      devOtp = await ref.read(authServiceProvider).sendSignupEmailOtp(_email.text);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      return;
    } finally {
      if (mounted) setState(() => _sendingEmailOtp = false);
    }
    if (!mounted) return;
    final ok = await _promptEmailOtp(devOtp: devOtp);
    if (ok == true && mounted) {
      setState(() {
        _emailVerified = true;
        _verifiedEmail = _email.text.trim().toLowerCase();
      });
      AppSnackbar.show(context, 'Email verified', success: true);
    }
  }

  Future<bool?> _promptEmailOtp({String? devOtp}) {
    final controller = TextEditingController(text: devOtp ?? '');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        bool verifying = false;
        bool resending = false;
        String? error;
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> submit() async {
              final code = controller.text.trim();
              if (code.length < 6) {
                setSheet(() => error = 'Enter the 6-digit code');
                return;
              }
              setSheet(() {
                verifying = true;
                error = null;
              });
              try {
                await ref.read(authServiceProvider).verifySignupEmailOtp(_email.text, code);
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(true);
              } catch (e) {
                setSheet(() {
                  verifying = false;
                  error = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            Future<void> resend() async {
              setSheet(() {
                resending = true;
                error = null;
              });
              try {
                final dev = await ref.read(authServiceProvider).sendSignupEmailOtp(_email.text);
                if (dev != null) controller.text = dev;
              } catch (e) {
                setSheet(() => error = e.toString().replaceFirst('Exception: ', ''));
              } finally {
                setSheet(() => resending = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Verify your email', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the 6-digit code sent to ${_email.text.trim()}',
                    style: GoogleFonts.inter(fontSize: 13, color: PremiumLoginTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      errorText: error,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: verifying ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumLoginTheme.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: verifying
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text('Verify', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: resending ? null : resend,
                      child: Text(resending ? 'Sending…' : 'Resend code', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Future<void> _verifyPhone() async {
    final l10n = context.l10n;
    final phoneError = Validators.phone(_phone.text, l10n);
    if (phoneError != null) {
      AppSnackbar.show(context, phoneError);
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      String? autoToken;
      final verificationId = await _phoneAuth.sendOtp(
        _phone.text,
        onAutoVerified: (token) => autoToken = token,
      );
      if (!mounted) return;
      if (autoToken != null) {
        _markVerified(autoToken!);
        return;
      }
      final token = await _promptOtpAndConfirm(verificationId);
      if (token != null && mounted) _markVerified(token);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e is AppException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  void _markVerified(String token) {
    setState(() {
      _phoneVerified = true;
      _phoneIdToken = token;
      _verifiedPhone = _phone.text.trim();
    });
    AppSnackbar.show(context, 'Phone number verified');
  }

  Future<String?> _promptOtpAndConfirm(String verificationId) {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        bool verifying = false;
        String? error;
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> submit() async {
              final code = controller.text.trim();
              if (code.length < 6) {
                setSheet(() => error = 'Enter the 6-digit code');
                return;
              }
              setSheet(() {
                verifying = true;
                error = null;
              });
              try {
                final token = await _phoneAuth.confirmOtp(verificationId, code);
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(token);
              } catch (e) {
                setSheet(() {
                  verifying = false;
                  error = e is AppException ? e.message : e.toString();
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Verify your phone',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the 6-digit code sent to ${PhoneAuthService.formatPhone(_phone.text)}',
                    style: GoogleFonts.inter(fontSize: 13, color: PremiumLoginTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      errorText: error,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: verifying ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumLoginTheme.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: verifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : Text('Verify', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _bloodGroup,
          dropdownColor: PremiumLoginTheme.white,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: PremiumLoginTheme.text,
          ),
          decoration: InputDecoration(
            labelText: 'Blood Group',
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
          items: ProfileOptions.bloodGroups
              .map((bg) => DropdownMenuItem<String>(value: bg, child: Text(bg)))
              .toList(),
          onChanged: (v) => setState(() => _bloodGroup = v),
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
          bottomGap: 0,
        ),
        _emailVerifyRow(),
        AuthInput(
          label: l10n.authPhone,
          icon: Icons.phone_outlined,
          controller: _phone,
          keyboardType: TextInputType.phone,
          hintText: l10n.authEnterPhoneHint,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        if (PhoneAuthService.isSupportedPlatform) _phoneVerifyRow(),
      ],
    );
  }

  Widget _emailVerifyRow() {
    if (_emailVerified) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 16),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
            const SizedBox(width: 8),
            Text(
              'Email verified',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _sendingEmailOtp ? null : _verifyEmail,
          icon: _sendingEmailOtp
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.mark_email_read_outlined, size: 18),
          label: Text(
            _sendingEmailOtp ? 'Sending code…' : 'Verify email via OTP',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(foregroundColor: PremiumLoginTheme.accentBlue),
        ),
      ),
    );
  }

  Widget _phoneVerifyRow() {
    if (_phoneVerified) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
            const SizedBox(width: 8),
            Text(
              'Phone verified',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _sendingOtp ? null : _verifyPhone,
          icon: _sendingOtp
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sms_outlined, size: 18),
          label: Text(
            _sendingOtp ? 'Sending code…' : 'Verify phone via OTP',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(foregroundColor: PremiumLoginTheme.accentBlue),
        ),
      ),
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
          bottomGap: 0,
        ),
        _passwordRequirements(),
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

  /// Live password checklist — shows while typing, disappears once every rule
  /// is satisfied (or when the field is empty).
  Widget _passwordRequirements() {
    final pwd = _password.text;
    if (pwd.isEmpty) return const SizedBox(height: 20);

    final rules = <({String label, bool ok})>[
      (label: 'At least 8 characters', ok: pwd.length >= 8),
      (label: 'One uppercase letter (A–Z)', ok: RegExp(r'[A-Z]').hasMatch(pwd)),
      (label: 'One lowercase letter (a–z)', ok: RegExp(r'[a-z]').hasMatch(pwd)),
      (label: 'One number (0–9)', ok: RegExp(r'\d').hasMatch(pwd)),
      (label: 'One special character (!@#…)', ok: RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(pwd)),
    ];

    if (rules.every((r) => r.ok)) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    r.ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    size: 16,
                    color: r.ok ? const Color(0xFF16A34A) : PremiumLoginTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: r.ok ? const Color(0xFF16A34A) : PremiumLoginTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
