import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/hospital_model.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/contact_navigation_utils.dart';
import '../../utils/location_utils.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/list_pagination.dart';
import '../../widgets/healthcare/premium_hospital_directory_widgets.dart';

enum _HospitalViewMode { all, nearby }

/// World-class MEDCLUES hospital directory — search, filters, premium cards.
class HospitalsListScreen extends ConsumerStatefulWidget {
  const HospitalsListScreen({super.key});

  @override
  ConsumerState<HospitalsListScreen> createState() => _HospitalsListScreenState();
}

class _HospitalsListScreenState extends ConsumerState<HospitalsListScreen> {
  final _searchController = TextEditingController();
  _HospitalViewMode _viewMode = _HospitalViewMode.all;
  List<HospitalModel> _nearbyHospitals = [];
  bool _loadingNearby = false;
  String? _nearbyError;
  int _page = 0;
  HospitalDirectorySort _sort = HospitalDirectorySort.name;
  bool _emergencyOnly = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _filterCount {
    var count = 0;
    if (_emergencyOnly) count++;
    if (_sort == HospitalDirectorySort.distance) count++;
    return count;
  }

  Future<void> _loadNearby(List<HospitalModel> partnered) async {
    setState(() {
      _loadingNearby = true;
      _nearbyError = null;
      _nearbyHospitals = [];
    });
    try {
      final loc = await getUserLocation();
      final list = await ref.read(hospitalServiceProvider).fetchNearby(
            lat: loc.lat,
            lon: loc.lon,
            partneredHospitals: partnered,
          );
      if (!mounted) return;
      setState(() {
        _nearbyHospitals = list;
        if (list.isEmpty) {
          _nearbyError = 'No hospitals found within 10km of your location.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _nearbyError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  void _onViewModeChanged(_HospitalViewMode mode, List<HospitalModel> partnered) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _page = 0;
      if (mode == _HospitalViewMode.all) {
        _sort = HospitalDirectorySort.name;
      }
    });
    if (mode == _HospitalViewMode.nearby) {
      _loadNearby(partnered);
    }
  }

  List<HospitalModel> _applyFilters(List<HospitalModel> source) {
    var list = List<HospitalModel>.from(source);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((h) =>
              h.name.toLowerCase().contains(q) ||
              h.address.toLowerCase().contains(q) ||
              (h.specialization?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (_emergencyOnly) {
      list = list.where((h) => h.emergencyAvailable == true).toList();
    }
    if (_sort == HospitalDirectorySort.distance) {
      list.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    } else {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  Future<void> _openFilterSheet() async {
    final result = await PremiumHospitalFilterSheet.show(
      context,
      sort: _sort,
      emergencyOnly: _emergencyOnly,
      showDistanceSort: _viewMode == _HospitalViewMode.nearby,
    );
    if (result == null || !mounted) return;
    setState(() {
      _sort = result.sort;
      _emergencyOnly = result.emergencyOnly;
      _page = 0;
    });
  }

  void _openHospital(HospitalModel h) {
    if (!h.canOpenDetails) {
      // Out-of-network hospital — there is no detail page, so take the user
      // straight to its exact spot on the map instead.
      _openOnMap(h);
      return;
    }
    context.push('/hospitals/${h.id}');
  }

  Future<void> _openOnMap(HospitalModel h) async {
    final ok = await ContactNavigationUtils.openHospitalLocation(
      latitude: h.latitude,
      longitude: h.longitude,
      mapsLink: h.mapsLink,
      hospitalName: h.name,
      address: h.address,
    );
    if (!ok && mounted) {
      AppSnackbar.show(context, 'Could not open maps for this hospital.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalsListProvider);

    return Scaffold(
      backgroundColor: PremiumHospitalDirectoryTheme.background(context),
      body: Column(
        children: [
          PremiumHospitalDirectoryHeader(
            searchController: _searchController,
            onSearchChanged: (v) => setState(() {
              _searchQuery = v;
              _page = 0;
            }),
            onFilter: _openFilterSheet,
            filterCount: _filterCount,
            onBack: () {
              final tour = ref.read(onboardingProvider);
              if (tour.phase == OnboardingPhase.tour && tour.tourIndex > 0) {
                ref.read(onboardingProvider.notifier).previousTourStep();
                return;
              }
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.dashboard);
              }
            },
          ),
          Expanded(
            child: hospitalsAsync.when(
              loading: () => const AppLoader(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: PremiumHospitalDirectoryTheme.textSecondary(context)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(hospitalsListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (partnered) {
                final raw = _viewMode == _HospitalViewMode.all ? partnered : _nearbyHospitals;
                final display = _applyFilters(raw);
                final showDistance = _viewMode == _HospitalViewMode.nearby;

                return Column(
                  children: [
                    PremiumHospitalSegmentedSwitch(
                      showNearby: _viewMode == _HospitalViewMode.nearby,
                      onAllTap: () => _onViewModeChanged(_HospitalViewMode.all, partnered),
                      onNearbyTap: () => _onViewModeChanged(_HospitalViewMode.nearby, partnered),
                    ),
                    if (_viewMode == _HospitalViewMode.nearby && _loadingNearby)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_viewMode == _HospitalViewMode.nearby && _nearbyError != null && display.isEmpty)
                      Expanded(
                        child: _EmptyState(
                          message: _nearbyError!,
                          onRetry: () => _loadNearby(partnered),
                          onSecondary: () => _onViewModeChanged(_HospitalViewMode.all, partnered),
                          secondaryLabel: 'View all hospitals',
                        ),
                      )
                    else if (display.isEmpty)
                      Expanded(
                        child: _EmptyState(
                          message: _viewMode == _HospitalViewMode.nearby
                              ? 'No nearby hospitals found'
                              : _searchQuery.isNotEmpty
                                  ? 'No hospitals match your search'
                                  : _emergencyOnly
                                      ? 'No emergency hospitals match your filter'
                                      : 'No hospitals found',
                          onRetry: _emergencyOnly || _searchQuery.isNotEmpty
                              ? () => setState(() {
                                    _emergencyOnly = false;
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _page = 0;
                                  })
                              : null,
                          onSecondary: _emergencyOnly || _searchQuery.isNotEmpty
                              ? () => setState(() {
                                    _emergencyOnly = false;
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _page = 0;
                                  })
                              : null,
                          secondaryLabel: _emergencyOnly || _searchQuery.isNotEmpty ? 'Clear filters' : null,
                        ),
                      )
                    else
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final totalPages = totalPagesFor(display.length);
                            final safePage = _page.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
                            if (safePage != _page) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _page = safePage);
                              });
                            }
                            final pageItems = paginateSlice(display, safePage);

                            return Column(
                              children: [
                                Expanded(
                                  child: RefreshIndicator(
                                    color: PremiumHospitalDirectoryTheme.healthcareTeal,
                                    onRefresh: () async {
                                      setState(() => _page = 0);
                                      ref.invalidate(hospitalsListProvider);
                                      if (_viewMode == _HospitalViewMode.nearby) {
                                        final list = await ref.read(hospitalsListProvider.future);
                                        await _loadNearby(list);
                                      }
                                    },
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        PremiumHospitalDirectoryTheme.horizontalPadding,
                                        4,
                                        PremiumHospitalDirectoryTheme.horizontalPadding,
                                        16,
                                      ),
                                      itemCount: pageItems.length,
                                      itemBuilder: (_, i) {
                                        final h = pageItems[i];
                                        return PremiumHospitalDirectoryCard(
                                          hospital: h,
                                          showDistance: showDistance,
                                          // Nearby view: a tap goes to the map at
                                          // the hospital's exact location. All view:
                                          // a tap opens the hospital detail page.
                                          onDetails: () => _viewMode == _HospitalViewMode.nearby
                                              ? _openOnMap(h)
                                              : _openHospital(h),
                                          onBook: h.canOpenDetails ? () => _openHospital(h) : null,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                PremiumHospitalDirectoryPagination(
                                  currentPage: safePage,
                                  totalItems: display.length,
                                  onPageChanged: (p) => setState(() => _page = p),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    this.onRetry,
    this.onSecondary,
    this.secondaryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 48,
              color: PremiumHospitalDirectoryTheme.textSecondary(context).withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: PremiumHospitalDirectoryTheme.textSecondary(context),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
            if (onSecondary != null && secondaryLabel != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ),
      ),
    );
  }
}
