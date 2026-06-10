import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/emergency/emergency_constants.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/common/language_selector.dart';
import '../../widgets/settings/telegram_connect_card.dart';

/// Matches mobile/app/(patient)/settings.tsx (theme preference).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LanguageSelectorCard(),
          const SizedBox(height: 16),
          const TelegramConnectCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dark_mode, color: cs.primary),
                    const SizedBox(width: 12),
                    Text(
                      l10n.settingsAppearance,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<AppThemePreference>(
                  segments: [
                    ButtonSegment(
                      value: AppThemePreference.system,
                      label: Text(l10n.settingsThemeSystem),
                      icon: const Icon(Icons.phone_android, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemePreference.light,
                      label: Text(l10n.settingsThemeLight),
                      icon: const Icon(Icons.light_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemePreference.dark,
                      label: Text(l10n.settingsThemeDark),
                      icon: const Icon(Icons.dark_mode, size: 18),
                    ),
                  ],
                  selected: {preference},
                  onSelectionChanged: (value) {
                    ref.read(themePreferenceProvider.notifier).setPreference(value.first);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  preference == AppThemePreference.system
                      ? l10n.settingsThemeSystemHint
                      : preference == AppThemePreference.dark
                          ? l10n.settingsThemeDarkHint
                          : l10n.settingsThemeLightHint,
                  style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline),
            ),
            tileColor: cs.surface,
            leading: const Icon(Icons.emergency, color: EmergencyConstants.emergencyRed),
            title: Text(
              l10n.settingsEmergency,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.settingsEmergencySubtitle,
              style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => context.push(RouteNames.emergencySettings),
          ),
          const SizedBox(height: 12),
          const EmergencyHelpButton(),
        ],
      ),
    );
  }
}
