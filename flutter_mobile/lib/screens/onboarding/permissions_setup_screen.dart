import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/storage_helper.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../services/app_permissions_service.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/booking/premium_booking_theme.dart';

/// First launch — triggers **native** Android/iOS permission dialogs one by one.
class PermissionsSetupScreen extends ConsumerStatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  ConsumerState<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends ConsumerState<PermissionsSetupScreen> {
  bool _running = false;
  PermissionStep? _activeStep;
  int _completed = 0;

  Future<void> _finishSetup() async {
    await ref.read(storageHelperProvider).setPermissionsSetupDone(true);
    await PushNotificationService.instance.init();
    if (!mounted) return;
    final auth = ref.read(authProvider);
    context.go(
      auth.status == AuthStatus.authenticated ? RouteNames.dashboard : RouteNames.login,
    );
  }

  Future<void> _startNativePermissionFlow() async {
    if (_running) return;
    setState(() {
      _running = true;
      _completed = 0;
      _activeStep = null;
    });

    try {
      await AppPermissionsService.requestOnboardingSequentially(
        onStepStarted: (step) {
          if (mounted) {
            setState(() {
              _activeStep = step;
              _completed = AppPermissionsService.onboardingSteps().indexWhere((s) => s.id == step.id);
            });
          }
        },
      );
      await _finishSetup();
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _activeStep = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishSetup());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = context.l10n;
    final steps = AppPermissionsService.onboardingSteps();
    final total = steps.length;

    return Scaffold(
      backgroundColor: PremiumBookingTheme.background(context),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    l10n.permissionsTitle,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: PremiumBookingTheme.text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.permissionsNativeHint,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: PremiumBookingTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_running && total > 0) ...[
                    LinearProgressIndicator(
                      value: total > 0 ? (_completed + 1) / total : null,
                      backgroundColor: PremiumBookingTheme.border(context),
                      color: PremiumBookingTheme.accentBlue,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.permissionsStepOf(_completed + 1, total),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: PremiumBookingTheme.textSecondary(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          _StepRow(
                            title: _stepLabel(l10n, steps[i]),
                            done: _running && i < _completed,
                            active: _activeStep?.id == steps[i].id,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _running ? null : _startNativePermissionFlow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumBookingTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _running ? l10n.permissionsPleaseRespond : l10n.permissionsAllowContinue,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _running ? null : _finishSetup,
                      child: Text(
                        l10n.permissionsLater,
                        style: GoogleFonts.inter(
                          color: PremiumBookingTheme.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_running && _activeStep != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.permissionsWaitingFor(_stepLabel(l10n, _activeStep!)),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.permissionsUseSystemDialog,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _stepLabel(dynamic l10n, PermissionStep step) {
    switch (step.id) {
      case 'notifications':
        return l10n.permissionsNotifications;
      case 'location':
        return l10n.permissionsLocation;
      case 'photos':
        return l10n.permissionsFiles;
      case 'camera':
        return l10n.permissionsCamera;
      case 'microphone':
        return l10n.permissionsMicrophone;
      case 'phone':
        return l10n.permissionsPhone;
      default:
        return step.title;
    }
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.done,
    required this.active,
  });

  final String title;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final icon = done
        ? Icons.check_circle_rounded
        : active
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded;
    final color = done
        ? PremiumBookingTheme.successGreen
        : active
            ? PremiumBookingTheme.accentBlue
            : PremiumBookingTheme.textSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: PremiumBookingTheme.text(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
