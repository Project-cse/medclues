import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/app_exception.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/brand_logo_mark.dart';
import '../../widgets/auth/login_screen_shell.dart';
import '../../widgets/auth/premium_login_theme.dart';
import '../../widgets/auth/premium_sign_in_button.dart';
import '../../services/google_auth_service.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/animations/app_motion.dart';
import '../../widgets/animations/healthcare_motion.dart';
import '../../widgets/animations/morph_action_button.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../widgets/common/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPwd = false;
  bool _googleLoading = false;
  MorphButtonState _btnState = MorphButtonState.idle;

  bool get _showGoogle => true;
  String? get _googleSetupHint => GoogleAuthService.setupHint;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
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
      if (msg != context.l10n.authSignInCancelled) {
        AppSnackbar.show(context, msg);
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final email = _email.text.trim();
    // Sign-in: only ensure fields are filled — do not re-validate password rules
    // (saved/autofill passwords may not meet signup complexity).
    if (Validators.loginEmail(email, l10n) != null) {
      AppSnackbar.show(context, l10n.validationEmailRequired);
      return;
    }
    if (Validators.loginPassword(_password.text, l10n) != null) {
      AppSnackbar.show(context, l10n.validationPasswordRequired);
      return;
    }
    setState(() => _btnState = MorphButtonState.loading);
    try {
      final ok = await ref.read(authProvider.notifier).login(
            email,
            _password.text,
          );
      if (!mounted) return;
      if (!ok) {
        setState(() => _btnState = MorphButtonState.idle);
        return;
      }
      setState(() => _btnState = MorphButtonState.success);
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      context.go(RouteNames.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _btnState = MorphButtonState.idle);
      final msg = e is AppException ? e.message : e.toString();
      AppSnackbar.show(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LoginScreenShell(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          children: [
            const BrandLogoMark(),
            const SizedBox(height: 16),
            Text(
              l10n.authSignInTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: PremiumLoginTheme.textSecondary,
                height: 1.4,
              ),
            ).authEnter(index: 1),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: PremiumLoginTheme.white,
                borderRadius: BorderRadius.circular(PremiumLoginTheme.cardRadius),
                boxShadow: PremiumLoginTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _userHeader(),
                  const SizedBox(height: 28),
                  AuthInput(
                    label: l10n.authEmail,
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    hintText: l10n.authEmailHint,
                    autofillHints: const [AutofillHints.email],
                  ),
                  _passwordSection(),
                  const SizedBox(height: 28),
                  PremiumSignInButton(
                    label: l10n.authSignIn,
                    state: _btnState,
                    onPressed: _btnState == MorphButtonState.idle ? _submit : null,
                  ),
                  if (_showGoogle) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: PremiumLoginTheme.inputBorder, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            l10n.commonOr,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: PremiumLoginTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: PremiumLoginTheme.inputBorder, height: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GoogleSignInButton(
                      loading: _googleLoading,
                      onPressed: (_btnState != MorphButtonState.idle || _googleLoading) ? null : _googleSignIn,
                    ),
                    if (_googleSetupHint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _googleSetupHint!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: PremiumLoginTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ).authFormEnter(index: 3),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push(RouteNames.signup),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: PremiumLoginTheme.textSecondary,
                  ),
                  children: [
                    TextSpan(text: l10n.authNoAccount),
                    TextSpan(
                      text: l10n.authRegister,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: PremiumLoginTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ).authFormEnter(index: 8),
            const SizedBox(height: 20),
            const EmergencyHelpButton().authFormEnter(index: 9),
          ],
        ),
      ),
    );
  }

  Widget _userHeader() {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: PremiumLoginTheme.avatarBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 26,
            color: PremiumLoginTheme.primaryBlue,
          ),
        ).authEnter(index: 5),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.authUser,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: PremiumLoginTheme.primaryBlue,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authUserSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: PremiumLoginTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.authPassword,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PremiumLoginTheme.text,
                letterSpacing: -0.1,
              ),
            ),
            GestureDetector(
              onTap: () {
                final email = _email.text.trim();
                final path = email.isNotEmpty
                    ? '${RouteNames.forgotPassword}?email=${Uri.encodeComponent(email)}'
                    : RouteNames.forgotPassword;
                context.push(path);
              },
              child: Text(
                l10n.authForgotPassword,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PremiumLoginTheme.accentBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AuthInput(
          label: '',
          icon: Icons.lock_outline_rounded,
          controller: _password,
          obscureText: !_showPwd,
          hintText: l10n.authPasswordHint,
          bottomGap: 0,
          autofillHints: const [AutofillHints.password],
          suffix: GestureDetector(
            onTap: () => setState(() => _showPwd = !_showPwd),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                _showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: PremiumLoginTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
