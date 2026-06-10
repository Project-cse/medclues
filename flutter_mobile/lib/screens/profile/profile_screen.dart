import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/common/app_loader.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../widgets/common/avatar_image.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(patientProfileProvider);
    final cs = Theme.of(context).colorScheme;
    final menu = [
      _MenuItem(Icons.person_outline, l10n.profilePersonalInfo, const Color(0xFF0EA5E9), const Color(0xFFEFF6FF), RouteNames.personalInfo),
      _MenuItem(Icons.payments_outlined, l10n.profilePayments, const Color(0xFF10B981), const Color(0xFFECFDF5), RouteNames.payments),
      _MenuItem(Icons.settings_outlined, l10n.profileSettings, const Color(0xFF64748B), const Color(0xFFF1F5F9), RouteNames.settings),
      _MenuItem(Icons.emergency, l10n.settingsEmergency, const Color(0xFFDC2626), const Color(0xFFFEE2E2), RouteNames.emergencySettings),
      _MenuItem(Icons.help_outline, l10n.profileHelp, const Color(0xFF0EA5E9), const Color(0xFFEFF6FF), RouteNames.help),
    ];

    return Scaffold(
      body: profile.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(patientProfileProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (p) => SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(patientProfileProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  l10n.profileTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    AvatarImage(uri: p.profilePicUrl, size: 100),
                    const SizedBox(height: 16),
                    Text(
                      p.name.trim().isEmpty ? 'USER' : p.name.trim().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.phone?.isNotEmpty == true ? p.phone! : l10n.validationPhoneRequired,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.email,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.profilePersonalInfo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: menu.asMap().entries.map((e) {
                      final item = e.value;
                      return InkWell(
                        onTap: () => context.push(item.route),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: e.key < menu.length - 1
                                ? Border(bottom: BorderSide(color: cs.outline))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? item.color.withValues(alpha: 0.18)
                                      : item.bg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon, color: item.color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const EmergencyHelpButton(),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(RouteNames.login);
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: Text(
                      l10n.profileLogout,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.color, this.bg, this.route);
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final String route;
}
