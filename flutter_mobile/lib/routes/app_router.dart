import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../onboarding/onboarding_tour_steps.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/appointments/appointment_detail_screen.dart';
import '../screens/appointments/appointment_summary_qr_screen.dart';
import '../screens/appointments/upcoming_appointments_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/booking/booking_patient_selector_screen.dart';
import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/booking/booking_receipt_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/booking/booking_success_screen.dart';
import '../screens/consultation/consultation_summary_screen.dart';
import '../screens/consultation/video_consult_screen.dart';
import '../screens/consultation/video_waiting_room_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/ai_assistant/ai_assistant_screen.dart';
import '../screens/doctors/doctor_profile_screen.dart';
import '../screens/doctors/doctors_list_screen.dart';
import '../screens/doctors/search_doctors_screen.dart';
import '../screens/search/home_search_screen.dart';
import '../screens/profile/about_screen.dart';
import '../screens/profile/contact_us_screen.dart';
import '../screens/profile/help_screen.dart';
import '../screens/profile/terms_screen.dart';
import '../screens/profile/payments_screen.dart';
import '../screens/profile/saved_profiles_screen.dart';
import '../widgets/common/force_light_theme.dart';
import '../features/emergency/screens/emergency_access_screen.dart';
import '../features/emergency/screens/emergency_active_screen.dart';
import '../features/emergency/screens/emergency_settings_screen.dart';
import '../screens/hospitals/hospital_details_screen.dart';
import '../screens/hospitals/hospitals_list_screen.dart';
import '../screens/labs/blood_bank_detail_screen.dart';
import '../screens/labs/blood_banks_list_screen.dart';
import '../models/blood_bank_model.dart';
import '../screens/labs/labs_list_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/records/records_screen.dart';
import '../screens/records/consultation_prescription_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/specialities/specialities_screen.dart';
import '../screens/symptom_search/symptom_search_screen.dart';
import '../screens/pharmacy/pharmacy_screen.dart';
import '../screens/medicine/medicine_search_screen.dart';
import '../screens/medicine/medicine_detail_screen.dart';
import '../screens/health_protection/health_protection_hub_screen.dart';
import '../screens/health_protection/hp_emergency_card_screen.dart';
import '../screens/health_protection/hp_recommend_screen.dart';
import '../screens/health_protection/hp_feature_screens.dart';
import '../screens/community/community_hub_screen.dart';
import '../screens/community/community_ask_screen.dart';
import '../screens/community/community_detail_screen.dart';
import '../brand/medclues_login_transition.dart';
import '../screens/onboarding/permissions_setup_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../l10n/l10n_extension.dart';
import 'route_names.dart';
import 'router_refresh.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

String? _authRedirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authProvider);
  final loc = state.matchedLocation;

  final isAuthScreen = loc == RouteNames.login ||
      loc == RouteNames.signup ||
      loc == RouteNames.forgotPassword;

  if (auth.status == AuthStatus.loading && loc == RouteNames.splash) {
    return null;
  }

  if (auth.status == AuthStatus.loading && isAuthScreen) {
    return null;
  }

  // While on the splash, let the SplashScreen drive its own exit (after the
  // intro video) instead of the router yanking it to the dashboard mid-video.
  if (loc == RouteNames.splash) {
    return null;
  }

  if (auth.status == AuthStatus.authenticated) {
    if (loc == RouteNames.login ||
        loc == RouteNames.signup ||
        loc == RouteNames.forgotPassword) {
      return RouteNames.dashboard;
    }

    // Tour redirect � soft tour stays on Home.
    final onboarding = ref.read(onboardingProvider);
    if (onboarding.needsOnboarding &&
        onboarding.phase == OnboardingPhase.tour) {
      if (!loc.startsWith('/a/')) {
        final idx = onboarding.tourIndex.clamp(0, onboardingTourSteps.length - 1);
        final expected = onboardingTourSteps[idx].route;
        if (loc != expected) return expected;
      }
    }

    final isEmergencyRoute = loc == RouteNames.emergency ||
        loc == RouteNames.emergencySettings ||
        loc == RouteNames.emergencyActive;
    if (isEmergencyRoute) return null;

    return null;
  }

  final isEmergencyRoute = loc == RouteNames.emergency ||
      loc == RouteNames.emergencySettings ||
      loc == RouteNames.emergencyActive;
  if (isEmergencyRoute) return null;

  if (loc.startsWith('/a/')) return null;

  if (loc == RouteNames.permissionsSetup) return null;

  if (auth.status == AuthStatus.unauthenticated ||
      auth.status == AuthStatus.error) {
    if (isAuthScreen ||
        loc == RouteNames.splash ||
        loc == RouteNames.permissionsSetup) {
      return null;
    }
    return RouteNames.login;
  }

  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final refresh = ref.watch(routerRefreshNotifierProvider);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _authRedirect(ref, state),
    routes: [
      GoRoute(
          path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: RouteNames.permissionsSetup,
        builder: (_, __) => const PermissionsSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) => MedcluesLoginTransition.page(
          child: const LoginScreen(),
          state: state,
        ),
      ),
      GoRoute(
          path: RouteNames.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            DashboardShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('shell-home'), child: DashboardScreen()),
          ),
          GoRoute(
            path: RouteNames.appointments,
            pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('shell-appointments'),
                child: UpcomingAppointmentsScreen()),
          ),
          GoRoute(
            path: '/records',
            pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('shell-records'), child: RecordsScreen()),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('shell-profile'), child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.aiAssistant,
        builder: (_, __) => const AiAssistantScreen(),
      ),
      GoRoute(
          path: RouteNames.specialities,
          builder: (_, __) => const SpecialitiesScreen()),
      GoRoute(
          path: RouteNames.homeSearch,
          builder: (_, __) => const HomeSearchScreen()),
      GoRoute(
          path: RouteNames.doctorSearch,
          builder: (_, __) => const SearchDoctorsScreen()),
      GoRoute(
        path: RouteNames.doctors,
        builder: (context, state) => DoctorsListScreen(
          speciality: state.uri.queryParameters['speciality'],
        ),
      ),
      GoRoute(
        path: '/doctors/:id',
        builder: (_, state) =>
            DoctorProfileScreen(doctorId: state.pathParameters['id']!),
      ),
      // Static /booking/* routes must come before /booking/:doctorId (else "confirmation" ? doctor id).
      GoRoute(
        path: '/booking/patient/:doctorId',
        builder: (_, state) => BookingPatientSelectorScreen(
          doctorId: state.pathParameters['doctorId']!,
          preferOnline: state.uri.queryParameters['visit'] == 'online',
        ),
      ),
      GoRoute(
          path: RouteNames.bookingConfirmation,
          builder: (_, __) => const BookingConfirmationScreen()),
      GoRoute(
          path: RouteNames.bookingSuccess,
          builder: (_, __) => const BookingSuccessScreen()),
      GoRoute(
        path: '/booking/receipt/:id',
        builder: (_, state) =>
            BookingReceiptScreen(appointmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:doctorId',
        builder: (_, state) => BookingScreen(
          doctorId: state.pathParameters['doctorId']!,
          preferOnline: state.uri.queryParameters['visit'] == 'online',
        ),
      ),
      GoRoute(
        path: '/appointment-detail/:id',
        redirect: (_, state) => '/appointments/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/records/prescription/:appointmentId',
        builder: (_, state) => ConsultationPrescriptionDetailScreen(
          appointmentId: state.pathParameters['appointmentId']!,
        ),
      ),
      GoRoute(
        path: '/appointments/:id',
        builder: (_, state) =>
            AppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/video-waiting/:appointmentId',
        builder: (_, state) => VideoWaitingRoomScreen(
            appointmentId: state.pathParameters['appointmentId']!),
      ),
      GoRoute(
        path: '/video-consult/:appointmentId',
        builder: (_, state) => VideoConsultScreen(
            appointmentId: state.pathParameters['appointmentId']!),
      ),
      GoRoute(
        path: '/consultation-summary/:appointmentId',
        builder: (_, state) => ConsultationSummaryScreen(
          appointmentId: state.pathParameters['appointmentId']!,
          durationSeconds:
              int.tryParse(state.uri.queryParameters['seconds'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
          path: RouteNames.notifications,
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: RouteNames.settings,
          builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: RouteNames.pharmacy,
          builder: (_, __) => const PharmacyScreen()),
      GoRoute(
          path: RouteNames.medicine,
          builder: (_, __) => const MedicineSearchScreen()),
      GoRoute(
        path: RouteNames.medicineDetail,
        builder: (_, state) {
          final name = Uri.decodeComponent(state.pathParameters['name'] ?? '');
          return MedicineDetailScreen(medicineName: name);
        },
      ),
      GoRoute(
          path: RouteNames.healthProtection,
          builder: (_, __) => const HealthProtectionHubScreen()),
      GoRoute(
          path: RouteNames.community,
          builder: (_, __) => const CommunityHubScreen()),
      GoRoute(
          path: RouteNames.communityAsk,
          builder: (_, __) => const CommunityAskScreen()),
      GoRoute(
        path: RouteNames.communityDetail,
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return CommunityDetailScreen(questionId: id);
        },
      ),
      GoRoute(
          path: RouteNames.hpRecommend,
          builder: (_, __) => const HpRecommendScreen()),
      GoRoute(
          path: RouteNames.hpCompare,
          builder: (_, __) => const HpCompareScreen()),
      GoRoute(
          path: RouteNames.hpEligibility,
          builder: (_, __) => const HpEligibilityScreen()),
      GoRoute(
          path: RouteNames.hpAnalyze,
          builder: (_, __) => const HpAnalyzeScreen()),
      GoRoute(
          path: RouteNames.hpClaims,
          builder: (_, __) => const HpClaimsScreen()),
      GoRoute(
        path: RouteNames.hpClaimDetail,
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return HpClaimDetailScreen(claimId: id);
        },
      ),
      GoRoute(
          path: RouteNames.hpCashless,
          builder: (_, __) => const HpCashlessScreen()),
      GoRoute(
          path: RouteNames.hpFamily,
          builder: (_, __) => const HpFamilyScreen()),
      GoRoute(
          path: RouteNames.hpExpenses,
          builder: (_, __) => const HpExpensesScreen()),
      GoRoute(
          path: RouteNames.hpRisk, builder: (_, __) => const HpRiskScreen()),
      GoRoute(
          path: RouteNames.hpChat, builder: (_, __) => const HpChatScreen()),
      GoRoute(
          path: RouteNames.hpEmergencyCard,
          builder: (_, __) => const HpEmergencyCardScreen()),
      GoRoute(
          path: RouteNames.hpAnalytics,
          builder: (_, __) => const HpAnalyticsScreen()),
      GoRoute(
          path: RouteNames.personalInfo,
          builder: (_, __) => const PersonalInfoScreen()),
      GoRoute(
          path: RouteNames.savedProfiles,
          builder: (_, __) => const SavedProfilesScreen()),
      GoRoute(
          path: RouteNames.payments,
          builder: (_, __) => const PaymentsScreen()),
      GoRoute(
          path: RouteNames.address,
          redirect: (_, __) => RouteNames.personalInfo),
      GoRoute(
          path: RouteNames.paymentHistory,
          redirect: (_, __) => RouteNames.payments),
      GoRoute(
          path: RouteNames.paymentMethods,
          redirect: (_, __) => RouteNames.payments),
      GoRoute(path: RouteNames.help, builder: (_, __) => const HelpScreen()),
      GoRoute(path: RouteNames.about, builder: (_, __) => const AboutScreen()),
      GoRoute(
          path: RouteNames.contactUs,
          builder: (_, __) => const ContactUsScreen()),
      GoRoute(path: RouteNames.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(
          path: RouteNames.hospitals,
          builder: (_, __) => const HospitalsListScreen()),
      GoRoute(
        path: '/hospitals/:id',
        builder: (_, state) =>
            HospitalDetailsScreen(hospitalId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: RouteNames.labs, builder: (_, __) => const LabsListScreen()),
      GoRoute(
          path: RouteNames.bloodBanks,
          builder: (_, __) => const BloodBanksListScreen()),
      GoRoute(
        path: RouteNames.symptomSearch,
        builder: (_, state) {
          final q = state.uri.queryParameters['q'];
          return SymptomSearchScreen(initialQuery: q);
        },
      ),
      GoRoute(
        path: '/blood-banks/:id',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is BloodBankModel) {
            return BloodBankDetailScreen(bank: extra);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Blood Bank')),
            body: const Center(child: Text('Blood bank not found')),
          );
        },
      ),
      GoRoute(
        path: RouteNames.emergency,
        builder: (_, __) =>
            const ForceLightTheme(child: EmergencyAccessScreen()),
      ),
      GoRoute(
        path: RouteNames.emergencySettings,
        builder: (_, __) =>
            const ForceLightTheme(child: EmergencySettingsScreen()),
      ),
      GoRoute(
        path: RouteNames.emergencyActive,
        builder: (_, __) =>
            const ForceLightTheme(child: EmergencyActiveScreen()),
      ),
      GoRoute(
        path: '/a/:bookingId',
        builder: (context, state) => AppointmentSummaryQrScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
          sig: state.uri.queryParameters['sig'],
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class DashboardShell extends StatefulWidget {
  const DashboardShell(
      {super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _indexFromLocation(String loc) {
    if (loc == RouteNames.appointments) return 1;
    if (loc == '/records') return 2;
    if (loc == RouteNames.profile) return 3;
    return 0;
  }

  void _onTap(int index) {
    if (_indexFromLocation(widget.location) == index) return;
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
        break;
      case 1:
        context.go(RouteNames.appointments);
        break;
      case 2:
        context.go('/records');
        break;
      case 3:
        context.go(RouteNames.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final idx = _indexFromLocation(widget.location);
    return Scaffold(
      // Keep tab content as the Scaffold body (not inside Positioned.fill),
      // then float the appointments strip above the bottom nav only.
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: _onTap,
        elevation: 12,
        shadowColor:
            Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.navAppointments,
          ),
          NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: l10n.navRecords),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile),
        ],
      ),
    );
  }
}
