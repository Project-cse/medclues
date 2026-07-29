import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../l10n/l10n_extension.dart';
import '../../constants/home_specialities.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../utils/speciality_match.dart';
import '../../utils/time_greeting.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/home/home_promo_carousel.dart';
import '../../widgets/home/home_search_bar.dart';
import '../../widgets/home/home_search_results.dart';
import '../../widgets/home/speciality_grid.dart';
import '../../widgets/home/today_appointments_overlay.dart';
import '../../services/doctor_service.dart';
import '../../widgets/home/top_doctor_card.dart';
import '../../widgets/home/top_doctors_grid.dart';
import '../../widgets/animations/healthcare_motion.dart';
import '../../onboarding/onboarding_tour_keys.dart';
import '../../widgets/layout/patient_drawer.dart';
import '../../widgets/home/home_search_scope.dart';
import '../../widgets/home/blinking_emergency_icon.dart';

/// Matches mobile/app/(patient)/home.tsx — inline search results on home.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  HomeSearchScope _searchScope = HomeSearchScope.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim());
    });
  }

  List<HomeSearchResultItem> _buildSearchResults(List<DoctorModel> doctors) {
    final l10n = context.l10n;
    final q = _query.toLowerCase();
    if (q.isEmpty) return [];
    final out = <HomeSearchResultItem>[];
    final scope = _searchScope;

    final services = <(String, String, String?, HomeSearchScope)>[
      (l10n.dashboardHospitals, RouteNames.hospitals, null, HomeSearchScope.hospitals),
      ('Doctors', RouteNames.doctors, null, HomeSearchScope.doctors),
      (l10n.dashboardLabs, RouteNames.labs, 'labs', HomeSearchScope.labsPharmacy),
      (l10n.dashboardBloodBanks, RouteNames.bloodBanks, 'blood', HomeSearchScope.labsPharmacy),
      ('By symptom', RouteNames.symptomSearch, null, HomeSearchScope.all),
      ('Pharmacy', RouteNames.pharmacy, null, HomeSearchScope.labsPharmacy),
      ('Medicines', RouteNames.medicine, null, HomeSearchScope.labsPharmacy),
      ('Emergency', RouteNames.emergency, null, HomeSearchScope.all),
    ];
    if (scope.allowsServices) {
      for (final s in services) {
        final matchesScope =
            scope == HomeSearchScope.all || s.$4 == scope;
        if (!matchesScope) continue;
        if (s.$1.toLowerCase().contains(q)) {
          out.add(HomeSearchResultItem.service(s.$1, s.$2, tab: s.$3));
        }
      }
    }

    if (scope.allowsSpecialities) {
      for (final sp in homeSpecialities) {
        if (sp.name.toLowerCase().contains(q) ||
            sp.filterKey.contains(q) ||
            matchesSpeciality(sp.name, q)) {
          out.add(HomeSearchResultItem.speciality(sp.name, sp.filterKey));
        }
      }
    }

    if (scope.allowsDoctors) {
      for (final d in doctors) {
        if (d.name.toLowerCase().contains(q) ||
            d.specialization.toLowerCase().contains(q) ||
            matchesSpeciality(d.specialization, q)) {
          out.add(HomeSearchResultItem.doctor(d));
        }
      }
    }

    final seen = <String>{};
    return out
        .where((r) {
          final key =
              r.type == 'doctor' ? 'd-${r.doctor!.id}' : '${r.type}-${r.label}';
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        })
        .take(12)
        .toList();
  }

  Future<void> _openSearchScopeSheet() async {
    final selected = await showHomeSearchScopeSheet(
      context,
      current: _searchScope,
    );
    if (selected != null && mounted) {
      setState(() => _searchScope = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final topDoctors = ref.watch(topDoctorsProvider);
    final allDoctors = ref.watch(allDoctorsProvider);
    final displayName = (user?.name ?? '').trim().toUpperCase();
    final greeting = timeBasedGreeting(l10n);
    final hasQuery = _query.isNotEmpty;
    final searchResults = hasQuery
        ? _buildSearchResults(allDoctors.valueOrNull ?? [])
        : <HomeSearchResultItem>[];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const PatientDrawer(),
      // Home owns this overlay so it cannot appear on other routes and the
      // drawer correctly covers it while the sidebar is open.
      bottomNavigationBar: const TodayAppointmentsOverlay(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.specCircleFill,
          onRefresh: () async {
            ref.read(doctorRepositoryProvider).invalidateCache();
            ref.invalidate(topDoctorsProvider);
            ref.invalidate(allDoctorsProvider);
            ref.invalidate(todayAppointmentsProvider);
            await ref.read(allDoctorsProvider.future);
          },
          child: ListView(
            children: [
              _header(context),
              // Greeting → carousel → quick access → search → specialities
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(
                  '${l10n.dashboardGreeting}${displayName.isNotEmpty ? ', $displayName' : ''} · $greeting 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.secondaryText,
                  ),
                ),
              ),
              if (hasQuery) ...[
                KeyedSubtree(
                  key: OnboardingTourKeys.search,
                  child: HomeSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onFilterTap: _openSearchScopeSheet,
                    filterActive: _searchScope != HomeSearchScope.all,
                  ),
                ),
                HomeSearchResults(
                  results: searchResults,
                  loading: allDoctors.isLoading,
                  onSelect: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ],
              if (!hasQuery) ...[
                const HomePromoCarousel().dashboardStagger(0),
                _quickAccessGrid(),
                // Search sits directly above specialities (requested home layout).
                KeyedSubtree(
                  key: OnboardingTourKeys.search,
                  child: HomeSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onFilterTap: _openSearchScopeSheet,
                    filterActive: _searchScope != HomeSearchScope.all,
                  ),
                ),
                _sectionTitle(l10n.dashboardSpecialities).dashboardStagger(2),
                const SpecialityGrid().dashboardStagger(3),
                const SizedBox(height: 8),
                _sectionTitleRow(l10n.dashboardTopDoctors,
                    () => context.push(RouteNames.doctors)),
                _topDoctorsSection(topDoctors, allDoctors),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, size: 26, color: context.secondaryText),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Row(
            children: [
              const Icon(Icons.medical_services,
                  size: 22, color: AppColors.logoTeal),
              const SizedBox(width: 6),
              Text(
                'MedClues',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.logoTeal,
                ),
              ),
            ],
          ),
          const Spacer(),
          KeyedSubtree(
            key: OnboardingTourKeys.emergency,
            child: const BlinkingEmergencyIconButton(),
          ),
          IconButton(
            tooltip: 'MedClues AI Assistant',
            onPressed: () => context.push(RouteNames.aiAssistant),
            icon: const Icon(Icons.auto_awesome_outlined, size: 24),
          ),
          Builder(
            builder: (context) {
              final unreadAsync = ref.watch(unreadNotificationsCountProvider);
              final count = unreadAsync.valueOrNull ?? 0;
              return IconButton(
                onPressed: () => context.push(RouteNames.notifications),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 24),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickAccessGrid() {
    final l10n = context.l10n;
    final items = [
      _QuickItem(
          l10n.dashboardHospitals,
          Icons.business,
          const Color(0xFFDC2626),
          const Color(0xFFE0F2FE),
          () => context.push(RouteNames.hospitals)),
      _QuickItem('Doctors', Icons.person, const Color(0xFF2563EB),
          const Color(0xFFE0F2FE), () => context.push(RouteNames.doctors)),
      _QuickItem(l10n.dashboardLabs, Icons.science, const Color(0xFF0284C7),
          const Color(0xFFE0F2FE), () => context.push(RouteNames.labs)),
      _QuickItem(
          l10n.dashboardBloodBanks,
          Icons.water_drop,
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
          () => context.push(RouteNames.bloodBanks)),
      _QuickItem(
          'By symptom',
          Icons.health_and_safety_outlined,
          const Color(0xFF059669),
          const Color(0xFFD1FAE5),
          () => context.push(RouteNames.symptomSearch)),
      _QuickItem('Pharmacy', Icons.medical_information, const Color(0xFFEA580C),
          const Color(0xFFFFEDD5), () => context.push(RouteNames.pharmacy)),
      _QuickItem('Medicines', Icons.biotech_outlined, const Color(0xFF0F766E),
          const Color(0xFFCCFBF1), () => context.push(RouteNames.medicine)),
      _QuickItem(
          'Health Protection',
          Icons.shield_moon_outlined,
          const Color(0xFF2563EB),
          const Color(0xFFDBEAFE),
          () => context.push(RouteNames.healthProtection)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 0,
        childAspectRatio: 0.85,
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final idx = entry.key;
          Widget tile = InkWell(
            onTap: () {
              if (item.onTap != null) {
                item.onTap!();
              } else {
                AppSnackbar.show(
                  context,
                  '${item.label} is not available in this build',
                );
              }
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: item.unique
                        ? Border.all(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.35))
                        : null,
                    boxShadow: item.unique
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: item.unique ? FontWeight.w700 : FontWeight.w500,
                    color: item.unique
                        ? const Color(0xFF003B8E)
                        : context.secondaryText,
                  ),
                ),
              ],
            ),
          );
          // Doctors tile: key outside stagger so tour hole stays accurate.
          if (idx == 1) {
            return KeyedSubtree(key: OnboardingTourKeys.doctors, child: tile);
          }
          return tile.dashboardStagger(idx + 1);
        }).toList(),
      ),
    );
  }

  Widget _topDoctorsSection(
    AsyncValue<List<DoctorModel>> topDoctors,
    AsyncValue<List<DoctorModel>> allDoctors,
  ) {
    if (topDoctors.isLoading && allDoctors.isLoading) {
      return _topDoctorsSkeleton();
    }

    final topList = topDoctors.valueOrNull;
    final allList = allDoctors.valueOrNull ?? [];
    final docs = (topList != null && topList.isNotEmpty)
        ? topList
        : DoctorService.pickTopDoctors(allList,
            limit: DoctorService.homeTopDoctorLimit);

    if (docs.isEmpty) {
      if (topDoctors.hasError && allDoctors.hasError) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$topDoctors.error',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(color: context.secondaryText, fontSize: 13),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No doctors available from the server.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: context.secondaryText),
        ),
      );
    }

    return TopDoctorsGrid(
      doctors: docs,
      onDoctorTap: (d) => context.push('/doctors/${d.id}'),
    );
  }

  Widget _topDoctorsSkeleton() {
    Widget row() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                child: _skeletonCard(),
              ),
            ),
          ),
        );

    return Column(
      children: [
        row(),
        const SizedBox(height: 16),
        row(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _skeletonCard() {
    return Container(
      width: TopDoctorCard.cardWidth,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.primaryText),
      ),
    );
  }

  Widget _sectionTitleRow(String title, VoidCallback onViewAll) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.primaryText),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              '${l10n.dashboardViewAll} >',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.specCircleFill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem(
    this.label,
    this.icon,
    this.iconColor,
    this.bg,
    this.onTap, {
    this.unique = false,
  });
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final VoidCallback? onTap;
  final bool unique;
}
