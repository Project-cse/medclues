import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../common/avatar_image.dart';

/// Side menu — matches mobile/components/layout/PatientDrawer.tsx (no Labs).
class PatientDrawer extends ConsumerWidget {
  const PatientDrawer({super.key});

  static const _items = <_DrawerItem>[
    _DrawerItem('Home', Icons.home_outlined, RouteNames.dashboard),
    _DrawerItem('Hospitals', Icons.business_outlined, RouteNames.hospitals),
    _DrawerItem('Doctors', Icons.medical_services_outlined, RouteNames.doctors),
    _DrawerItem('Appointments', Icons.calendar_today_outlined, RouteNames.appointments),
    _DrawerItem('Pharmacy', Icons.local_pharmacy_outlined, RouteNames.pharmacy),
    _DrawerItem('Medicines', Icons.medication_outlined, RouteNames.medicine),
    _DrawerItem('Health Protection', Icons.health_and_safety_outlined, RouteNames.healthProtection),
    _DrawerItem('Health Community', Icons.forum_outlined, RouteNames.community),
    _DrawerItem('Records', Icons.assignment_outlined, '/records'),
    _DrawerItem('Profile', Icons.person_outline, RouteNames.profile),
    _DrawerItem('Settings', Icons.settings_outlined, RouteNames.settings),
  ];

  static const _legalItems = <_DrawerItem>[
    _DrawerItem('Contact Us', Icons.support_agent_outlined, RouteNames.contactUs),
    _DrawerItem('About', Icons.info_outline, RouteNames.about),
    _DrawerItem('Terms & Conditions', Icons.description_outlined, RouteNames.terms),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).user;
    final profile = ref.watch(patientProfileProvider);
    final name = (profile.valueOrNull?.name ?? auth?.name ?? 'User').toUpperCase();
    final email = profile.valueOrNull?.email ?? auth?.email ?? '';
    final avatar = profile.valueOrNull?.profilePicUrl ?? auth?.imageUrl;

    final cs = Theme.of(context).colorScheme;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82 > 300 ? 300 : MediaQuery.sizeOf(context).width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarImage(uri: avatar, size: 64),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          final pref = ref.watch(themePreferenceProvider);
                          final isDark = pref == AppThemePreference.dark ||
                              (pref == AppThemePreference.system &&
                                  Theme.of(context).brightness ==
                                      Brightness.dark);
                          return IconButton(
                            tooltip: isDark ? 'Light mode' : 'Dark mode',
                            onPressed: () => ref
                                .read(themePreferenceProvider.notifier)
                                .toggle(),
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 24,
                              color: cs.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline),
            Expanded(
              child: ListView(
                children: [
                  for (final item in _items)
                    _menuTile(context, item: item, color: cs),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  for (final item in _legalItems)
                    _menuTile(context, item: item, color: cs),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error, size: 22),
                    title: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(RouteNames.login);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                '© ${DateTime.now().year} MEDCLUES. All rights reserved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  height: 1.3,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _menuTile(BuildContext context, {required _DrawerItem item, required ColorScheme color}) {
  return ListTile(
    leading: Icon(item.icon, color: AppColors.brandBlue, size: 22),
    title: Text(
      item.label,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color.onSurface,
      ),
    ),
    onTap: () {
      Navigator.of(context).pop();
      final path = item.route;
      if (path == RouteNames.dashboard ||
          path == RouteNames.appointments ||
          path == RouteNames.profile ||
          path == '/records') {
        context.go(path);
      } else {
        context.push(path);
      }
    },
  );
}

class _DrawerItem {
  const _DrawerItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
