import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../helpers/storage_helper.dart';
import '../onboarding/onboarding_tour_steps.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/appointments/appointment_detail_screen.dart';
import '../screens/appointments/upcoming_appointments_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/booking/booking_patient_selector_screen.dart';
import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/booking/booking_receipt_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/booking/booking_success_screen.dart';
import '../screens/consultation/video_consult_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/doctors/doctor_profile_screen.dart';
import '../screens/doctors/doctors_list_screen.dart';
import '../screens/doctors/search_doctors_screen.dart';
import '../screens/search/home_search_screen.dart';
import '../screens/profile/about_screen.dart';
import '../screens/profile/help_screen.dart';
import '../screens/profile/terms_screen.dart';
import '../screens/profile/payments_screen.dart';
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
import '../screens/settings/settings_screen.dart';
import '../screens/specialities/specialities_screen.dart';
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

  if (auth.status == AuthStatus.authenticated) {
    if (loc == RouteNames.login ||
        loc == RouteNames.signup ||
        loc == RouteNames.splash ||
        loc == RouteNames.forgotPassword) {
      return RouteNames.dashboard;
    }

    // Tour redirect takes priority — keeps user on the correct tab (incl. step 6 /emergency).
    final onboarding = ref.read(onboardingProvider);
    if (onboarding.needsOnboarding && onboarding.phase == OnboardingPhase.tour) {
      final idx = onboarding.tourIndex.clamp(0, onboardingTourSteps.length - 1);
      final expected = onboardingTourSteps[idx].route;
      if (loc != expected) return expected;
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

  if (loc == RouteNames.permissionsSetup) return null;

  if (auth.status == AuthStatus.unauthenticated || auth.status == AuthStatus.error) {
    if (isAuthScreen || loc == RouteNames.splash || loc == RouteNames.permissionsSetup) {
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
      GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
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
      GoRoute(path: RouteNames.signup, builder: (_, __) => const SignupScreen()),
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
            pageBuilder: (_, __) => const NoTransitionPage(key: ValueKey('shell-home'), child: DashboardScreen()),
          ),
          GoRoute(
            path: RouteNames.appointments,
            pageBuilder: (_, __) =>
                const NoTransitionPage(key: ValueKey('shell-appointments'), child: UpcomingAppointmentsScreen()),
          ),
          GoRoute(
            path: '/records',
            pageBuilder: (_, __) => const NoTransitionPage(key: ValueKey('shell-records'), child: RecordsScreen()),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (_, __) => const NoTransitionPage(key: ValueKey('shell-profile'), child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(path: RouteNames.specialities, builder: (_, __) => const SpecialitiesScreen()),
      GoRoute(path: RouteNames.homeSearch, builder: (_, __) => const HomeSearchScreen()),
      GoRoute(path: RouteNames.doctorSearch, builder: (_, __) => const SearchDoctorsScreen()),
      GoRoute(
        path: RouteNames.doctors,
        builder: (context, state) => DoctorsListScreen(
          speciality: state.uri.queryParameters['speciality'],
        ),
      ),
      GoRoute(
        path: '/doctors/:id',
        builder: (_, state) => DoctorProfileScreen(doctorId: state.pathParameters['id']!),
      ),
      // Static /booking/* routes must come before /booking/:doctorId (else "confirmation" → doctor id).
      GoRoute(
        path: '/booking/patient/:doctorId',
        builder: (_, state) => BookingPatientSelectorScreen(
          doctorId: state.pathParameters['doctorId']!,
          preferOnline: state.uri.queryParameters['visit'] == 'online',
        ),
      ),
      GoRoute(path: RouteNames.bookingConfirmation, builder: (_, __) => const BookingConfirmationScreen()),
      GoRoute(path: RouteNames.bookingSuccess, builder: (_, __) => const BookingSuccessScreen()),
      GoRoute(
        path: '/booking/receipt/:id',
        builder: (_, state) => BookingReceiptScreen(appointmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:doctorId',
        builder: (_, state) => BookingScreen(
          doctorId: state.pathParameters['doctorId']!,
          preferOnline: state.uri.queryParameters['visit'] == 'online',
        ),
      ),
      GoRoute(
        path: '/appointments/:id',
        builder: (_, state) => AppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/video-consult/:appointmentId',
        builder: (_, state) => VideoConsultScreen(appointmentId: state.pathParameters['appointmentId']!),
      ),
      GoRoute(path: RouteNames.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: RouteNames.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: RouteNames.personalInfo, builder: (_, __) => const PersonalInfoScreen()),
      GoRoute(path: RouteNames.payments, builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: RouteNames.address, redirect: (_, __) => RouteNames.personalInfo),
      GoRoute(path: RouteNames.paymentHistory, redirect: (_, __) => RouteNames.payments),
      GoRoute(path: RouteNames.paymentMethods, redirect: (_, __) => RouteNames.payments),
      GoRoute(path: RouteNames.help, builder: (_, __) => const HelpScreen()),
      GoRoute(path: RouteNames.about, builder: (_, __) => const AboutScreen()),
      GoRoute(path: RouteNames.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(path: RouteNames.hospitals, builder: (_, __) => const HospitalsListScreen()),
      GoRoute(
        path: '/hospitals/:id',
        builder: (_, state) => HospitalDetailsScreen(hospitalId: state.pathParameters['id']!),
      ),
      GoRoute(path: RouteNames.labs, builder: (_, __) => const LabsListScreen()),
      GoRoute(path: RouteNames.bloodBanks, builder: (_, __) => const BloodBanksListScreen()),
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
        builder: (_, __) => const ForceLightTheme(child: EmergencyAccessScreen()),
      ),
      GoRoute(
        path: RouteNames.emergencySettings,
        builder: (_, __) => const ForceLightTheme(child: EmergencySettingsScreen()),
      ),
      GoRoute(
        path: RouteNames.emergencyActive,
        builder: (_, __) => const ForceLightTheme(child: EmergencyActiveScreen()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.child, required this.location});

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
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: _onTap,
        elevation: 12,
        shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.navHome),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.navAppointments,
          ),
          NavigationDestination(icon: const Icon(Icons.folder_outlined), selectedIcon: const Icon(Icons.folder), label: l10n.navRecords),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.navProfile),
        ],
      ),
    );
  }
}
