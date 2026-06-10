import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n_extension.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../emergency_constants.dart';
import '../models/emergency_case_model.dart';
import '../providers/emergency_provider.dart';
import '../services/emergency_notification_service.dart';
import '../widgets/emergency_action_button.dart';
import '../widgets/emergency_home_button.dart';
import '../widgets/emergency_whatsapp_contacts_panel.dart';

/// Post-SOS screen with calls, location, hospitals, and contacts.
class EmergencyActiveScreen extends ConsumerWidget {
  const EmergencyActiveScreen({super.key});

  Future<void> _serviceCall(BuildContext context, String number, String label) async {
    final l10n = context.l10n;
    if (EmergencyConstants.testingMode) {
      AppSnackbar.show(
        context,
        '${l10n.emergencyTestingBlocked}: $label ($number)',
      );
      return;
    }
    final ok = await launchEmergencyServiceCall(number: number, label: label);
    if (!ok && context.mounted) {
      AppSnackbar.show(context, l10n.emergencyCallFailed(label));
    }
  }

  Future<void> _shareAlertWhatsApp(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final settings = await ref.read(emergencySettingsProvider.future);
    final session = ref.read(emergencySessionProvider);
    final notify = ref.read(emergencyNotificationProvider);
    final msg = notify.buildAlertMessage(
      settings: settings,
      location: session.location,
      extraNote: session.activeCase?.symptoms.isNotEmpty == true
          ? 'Symptoms: ${session.activeCase!.symptoms.join(', ')}'
          : null,
    );
    final contacts = settings.savedContacts;
    if (contacts.isEmpty) {
      await notify.manualShare(msg);
      if (context.mounted) {
        AppSnackbar.show(context, l10n.emergencyNoRelatives);
      }
    } else {
      await notify.openWhatsAppMessage(phone: contacts.first.phone, message: msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(emergencySessionProvider);
    final caseModel = session.activeCase;
    final severity = caseModel?.severity ?? EmergencySeverity.critical;
    final settingsAsync = ref.watch(emergencySettingsProvider);
    final hasContacts = settingsAsync.value?.savedContacts.isNotEmpty == true;

    return Scaffold(
      backgroundColor: EmergencyConstants.emergencyBg,
      appBar: AppBar(
        backgroundColor: EmergencyConstants.emergencyRed,
        foregroundColor: Colors.white,
        title: Text(l10n.emergencyActiveTitle),
        leading: const EmergencyHomeButton(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (EmergencyConstants.testingMode) _testingBanner(context),
            _statusHeader(context, severity),
            const SizedBox(height: 16),
            const EmergencyWhatsappContactsPanel(),
            if (hasContacts) const SizedBox(height: 8),
            if (severity == EmergencySeverity.critical) ..._criticalActions(context, ref),
            if (severity == EmergencySeverity.moderate) ..._moderateActions(context, ref),
            if (severity == EmergencySeverity.minor) ..._minorActions(context),
            const SizedBox(height: 8),
            EmergencyActionButton(
              label: l10n.emergencyShareLocation,
              subtitle: hasContacts
                  ? l10n.emergencyWhatsappAlert
                  : l10n.emergencyNoRelatives,
              icon: Icons.share_location,
              filled: false,
              onTap: () => _shareAlertWhatsApp(context, ref),
            ),
            if (session.location != null)
              EmergencyActionButton(
                label: l10n.receiptLocation,
                subtitle: session.location!.mapsLink,
                icon: Icons.map,
                filled: false,
                onTap: () => ref.read(emergencyLocationProvider).openMapsLink(session.location!.mapsLink),
              ),
            EmergencyActionButton(
              label: l10n.emergencySettings,
              icon: Icons.settings,
              filled: false,
              onTap: () => context.push(RouteNames.emergencySettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testingBanner(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEA580C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Color(0xFFEA580C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.emergencyTestingBlocked,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusHeader(BuildContext context, EmergencySeverity severity) {
    final l10n = context.l10n;
    final (title, color) = switch (severity) {
      EmergencySeverity.critical => (l10n.emergencySeverityCritical, EmergencyConstants.emergencyRed),
      EmergencySeverity.moderate => (l10n.emergencySeverityModerate, const Color(0xFFEA580C)),
      EmergencySeverity.minor => (l10n.emergencySeverityMinor, const Color(0xFF2563EB)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.emergency, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _criticalActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return [
      EmergencyActionButton(
        label: l10n.emergencyCallAmbulance,
        subtitle: EmergencyConstants.testingMode
            ? '${EmergencyConstants.ambulance} (disabled in testing)'
            : EmergencyConstants.ambulance,
        icon: Icons.local_hospital,
        onTap: () => _serviceCall(context, EmergencyConstants.ambulance, l10n.emergencyAmbulance),
      ),
      EmergencyActionButton(
        label: l10n.emergencyCallPoliceBtn,
        subtitle: EmergencyConstants.testingMode
            ? 'Disabled in testing'
            : '${EmergencyConstants.police} / ${EmergencyConstants.policeAlt}',
        icon: Icons.local_police,
        onTap: () => _serviceCall(context, EmergencyConstants.police, l10n.emergencyPolice),
      ),
      EmergencyActionButton(
        label: l10n.emergencyCallFireBtn,
        subtitle: EmergencyConstants.testingMode
            ? '${EmergencyConstants.fire} (disabled in testing)'
            : EmergencyConstants.fire,
        icon: Icons.local_fire_department,
        filled: false,
        onTap: () => _serviceCall(context, EmergencyConstants.fire, l10n.emergencyFire),
      ),
      EmergencyActionButton(
        label: l10n.emergencyNearbyHospitals,
        icon: Icons.place,
        filled: false,
        onTap: () => ref.read(emergencyLocationProvider).openNearbyHospitals(
              location: ref.read(emergencySessionProvider).location,
            ),
      ),
    ];
  }

  List<Widget> _moderateActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return [
      EmergencyActionButton(
        label: l10n.emergencyBookConsultation,
        subtitle: l10n.emergencyConnectDoctors,
        icon: Icons.video_call,
        onTap: () => context.push('${RouteNames.doctors}?visit=online'),
      ),
      EmergencyActionButton(
        label: l10n.emergencyNearbyHospitals,
        icon: Icons.place,
        filled: false,
        onTap: () => ref.read(emergencyLocationProvider).openNearbyHospitals(
              location: ref.read(emergencySessionProvider).location,
            ),
      ),
      EmergencyActionButton(
        label: l10n.emergencyShareLocation,
        subtitle: l10n.emergencyWhatsappAlert,
        icon: Icons.chat,
        filled: false,
        onTap: () => _shareAlertWhatsApp(context, ref),
      ),
      EmergencyActionButton(
        label: l10n.emergencyCallAmbulance,
        subtitle: EmergencyConstants.testingMode
            ? '${EmergencyConstants.ambulance} (disabled in testing)'
            : EmergencyConstants.ambulance,
        icon: Icons.local_hospital,
        filled: false,
        onTap: () => _serviceCall(context, EmergencyConstants.ambulance, l10n.emergencyAmbulance),
      ),
    ];
  }

  List<Widget> _minorActions(BuildContext context) {
    final l10n = context.l10n;
    return [
      EmergencyActionButton(
        label: l10n.emergencyBookConsultation,
        subtitle: l10n.emergencyScheduleVisit,
        icon: Icons.calendar_month,
        onTap: () => context.push(RouteNames.doctors),
      ),
      EmergencyActionButton(
        label: l10n.emergencyCallAmbulance,
        subtitle: EmergencyConstants.testingMode
            ? 'Disabled in testing'
            : 'If condition worsens',
        icon: Icons.local_hospital,
        filled: false,
        onTap: () => _serviceCall(context, EmergencyConstants.ambulance, l10n.emergencyAmbulance),
      ),
    ];
  }
}
