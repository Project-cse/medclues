import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../utils/validators.dart';
import '../../widgets/animations/app_motion.dart';
import '../../widgets/auth/brand_logo_mark.dart';
import '../../widgets/auth/login_screen_shell.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = context.l10n;
    final emailError = Validators.email(_email.text, l10n);
    if (emailError != null) {
      AppSnackbar.show(context, l10n.authEnterValidEmail);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).forgotPassword(_email.text);
      setState(() => _otpSent = true);
      AppSnackbar.show(context, l10n.authOtpSent, success: true);
    } catch (e) {
      AppSnackbar.show(context, e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final otpError = Validators.otp(_otp.text, l10n);
    final passwordError = Validators.password(_password.text, l10n);
    final confirmError = Validators.confirmPassword(_confirm.text, _password.text, l10n);
    if (otpError != null) {
      AppSnackbar.show(context, otpError);
      return;
    }
    if (passwordError != null) {
      AppSnackbar.show(context, passwordError);
      return;
    }
    if (confirmError != null) {
      AppSnackbar.show(context, confirmError);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).verifyOtp(_email.text, _otp.text);
      await ref.read(authServiceProvider).resetPassword(_email.text, _otp.text, _password.text);
      AppSnackbar.show(context, l10n.authPasswordResetSuccess, success: true);
      if (mounted) context.go(RouteNames.login);
    } catch (e) {
      AppSnackbar.show(context, e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LoginScreenShell(
      child: Column(
        children: [
          const BrandLogoMark(),
          BrandHeaderText(
            headline: l10n.authResetPassword,
            subheadline: l10n.authForgotSubtitle,
            animationIndex: 1,
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.loginCard,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: l10n.authEmail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => Validators.email(v, l10n),
                  ).authEnter(index: 4),
                  const SizedBox(height: 16),
                  if (_otpSent) ...[
                    AppTextField(
                      label: l10n.authOtp,
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.otp(v, l10n),
                    ).authEnter(index: 5),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: l10n.authNewPassword,
                      controller: _password,
                      obscureText: true,
                      validator: (v) => Validators.password(v, l10n),
                    ).authEnter(index: 6),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: l10n.authConfirmPassword,
                      controller: _confirm,
                      obscureText: true,
                      validator: (v) => Validators.confirmPassword(v, _password.text, l10n),
                    ).authEnter(index: 7),
                    const SizedBox(height: 16),
                    AppButton(label: l10n.authResetPassword, loading: _loading, onPressed: _reset)
                        .buttonPop(index: 8),
                  ] else
                    AppButton(label: l10n.authSendOtp, loading: _loading, onPressed: _sendOtp)
                        .buttonPop(index: 5),
                ],
              ),
            ),
          ).authEnter(index: 3),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(RouteNames.login),
            child: Text(
              l10n.authBackToLogin,
              style: GoogleFonts.poppins(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).authEnter(index: 9),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
