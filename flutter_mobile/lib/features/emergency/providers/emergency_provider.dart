import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_case_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/emergency_settings_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../services/emergency_location_service.dart';
import '../services/emergency_notification_service.dart';
import '../services/emergency_storage_service.dart';

final emergencyStorageProvider = Provider<EmergencyStorageService>((ref) {
  return EmergencyStorageService();
});

final emergencyLocationProvider = Provider<EmergencyLocationService>((ref) {
  return EmergencyLocationService();
});

final emergencyNotificationProvider = Provider<EmergencyNotificationService>((ref) {
  return EmergencyNotificationService();
});

final emergencySettingsProvider =
    AsyncNotifierProvider<EmergencySettingsNotifier, EmergencySettingsModel>(EmergencySettingsNotifier.new);

class EmergencySettingsNotifier extends AsyncNotifier<EmergencySettingsModel> {
  @override
  Future<EmergencySettingsModel> build() async {
    return ref.read(emergencyStorageProvider).loadSettings();
  }

  Future<void> save(EmergencySettingsModel settings) async {
    await ref.read(emergencyStorageProvider).saveSettings(settings);
    state = AsyncData(settings);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(emergencyStorageProvider).loadSettings());
  }

  /// Saves the first emergency contact locally (tutorial / onboarding).
  Future<void> upsertPrimaryContact(EmergencyContactModel contact) async {
    final current = await ref.read(emergencyStorageProvider).loadSettings();
    await save(current.copyWith(relativeContact1: contact));
  }

  /// Pull server contacts into local storage so Emergency settings & SOS see them.
  Future<void> syncRemoteContactsFromApi() async {
    try {
      final remote = await ref.read(emergencyApiServiceProvider).fetchContacts();
      if (remote.isEmpty) return;
      final current = await ref.read(emergencyStorageProvider).loadSettings();
      await save(
        current.copyWith(
          relativeContact1: remote.first,
          relativeContact2: remote.length > 1 ? remote[1] : current.relativeContact2,
        ),
      );
    } catch (_) {
      // Offline or API unavailable — keep local data
    }
  }
}

class EmergencySessionState {
  const EmergencySessionState({
    this.activeCase,
    this.location,
    this.isActivating = false,
  });

  final EmergencyCaseModel? activeCase;
  final EmergencyLocationData? location;
  final bool isActivating;

  EmergencySessionState copyWith({
    EmergencyCaseModel? activeCase,
    EmergencyLocationData? location,
    bool? isActivating,
  }) {
    return EmergencySessionState(
      activeCase: activeCase ?? this.activeCase,
      location: location ?? this.location,
      isActivating: isActivating ?? this.isActivating,
    );
  }
}

class EmergencySessionNotifier extends Notifier<EmergencySessionState> {
  @override
  EmergencySessionState build() => const EmergencySessionState();

  Future<EmergencyCaseModel> activateSos({
    required EmergencyTriggerType triggerType,
    required EmergencySeverity severity,
    List<String> symptoms = const [],
    bool isHelperFlow = false,
    String? notes,
  }) async {
    state = state.copyWith(isActivating: true);
    final storage = ref.read(emergencyStorageProvider);
    final locationSvc = ref.read(emergencyLocationProvider);
    final settings = await ref.read(emergencySettingsProvider.future);

    EmergencyLocationData? loc;
    if (settings.autoLocationSharing) {
      loc = await locationSvc.getCurrentLocation();
    }

    final caseModel = EmergencyCaseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      triggerType: triggerType,
      severity: severity,
      symptoms: symptoms,
      latitude: loc?.latitude,
      longitude: loc?.longitude,
      mapsLink: loc?.mapsLink,
      isHelperFlow: isHelperFlow,
      notes: notes,
    );

    await storage.saveCase(caseModel);

    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      await ref.read(emergencyApiServiceProvider).logSosEvent(caseModel);
    }

    final contacts = (await ref.read(emergencySettingsProvider.future)).savedContacts;
    if (contacts.isNotEmpty && severity == EmergencySeverity.critical) {
      final msg = ref.read(emergencyNotificationProvider).buildAlertMessage(
            settings: settings,
            location: loc,
            extraNote: symptoms.isNotEmpty ? 'Symptoms: ${symptoms.join(', ')}' : null,
          );
      await ref.read(emergencyNotificationProvider).notifyContacts(contacts: contacts, message: msg);
    }

    state = EmergencySessionState(activeCase: caseModel, location: loc, isActivating: false);
    return caseModel;
  }

  void clear() => state = const EmergencySessionState();
}

final emergencySessionProvider =
    NotifierProvider<EmergencySessionNotifier, EmergencySessionState>(EmergencySessionNotifier.new);
