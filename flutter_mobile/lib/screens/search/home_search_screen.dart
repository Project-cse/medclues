import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_specialities.dart';
import '../../models/doctor_model.dart';
import '../../providers/doctor_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/speciality_match.dart';
import '../../widgets/home/home_search_scope.dart';

/// Matches mobile useHomeSearch + HomeSearchResults.
class HomeSearchScreen extends ConsumerStatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  ConsumerState<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends ConsumerState<HomeSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  HomeSearchScope _scope = HomeSearchScope.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openScopeSheet() async {
    final selected = await showHomeSearchScopeSheet(context, current: _scope);
    if (selected != null && mounted) {
      setState(() => _scope = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final doctorsAsync = q.isEmpty ? null : ref.watch(doctorSearchProvider(q));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search services, doctors, hospitals...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          IconButton(
            tooltip: 'Search filters',
            onPressed: _openScopeSheet,
            icon: Badge(
              isLabelVisible: _scope != HomeSearchScope.all,
              smallSize: 8,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: q.isEmpty
          ? Center(
              child: Text('Type to search', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            )
          : doctorsAsync!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (doctors) {
                final results = _buildResults(q, doctors);
                if (results.isEmpty) {
                  return Center(
                    child: Text('No results', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return ListTile(
                      leading: Icon(r.icon, color: AppColors.specCircleFill),
                      title: Text(r.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: r.subtitle != null
                          ? Text(
                              r.subtitle!,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                            )
                          : null,
                      onTap: () => _onResultTap(context, r),
                    );
                  },
                );
              },
            ),
    );
  }

  List<_SearchResult> _buildResults(String q, List<DoctorModel> doctors) {
    final lower = q.toLowerCase();
    final out = <_SearchResult>[];
    final scope = _scope;

    final services = <(String, IconData, String, HomeSearchScope)>[
      ('Hospitals', Icons.business, RouteNames.hospitals, HomeSearchScope.hospitals),
      ('Doctors', Icons.person, RouteNames.doctors, HomeSearchScope.doctors),
      ('Labs', Icons.science, RouteNames.labs, HomeSearchScope.labsPharmacy),
      ('Blood Banks', Icons.water_drop, RouteNames.bloodBanks, HomeSearchScope.labsPharmacy),
      ('Pharmacy', Icons.medical_information, RouteNames.pharmacy, HomeSearchScope.labsPharmacy),
      ('Emergency', Icons.warning, RouteNames.emergency, HomeSearchScope.all),
    ];
    if (scope.allowsServices) {
      for (final s in services) {
        if (scope != HomeSearchScope.all && s.$4 != scope) continue;
        if (s.$1.toLowerCase().contains(lower)) {
          out.add(_SearchResult(s.$1, s.$2, route: s.$3));
        }
      }
    }

    if (scope.allowsSpecialities) {
      for (final sp in homeSpecialities) {
        if (sp.name.toLowerCase().contains(lower) ||
            sp.filterKey.contains(lower) ||
            matchesSpeciality(sp.name, lower)) {
          out.add(_SearchResult(
            sp.name,
            Icons.category_outlined,
            route: RouteNames.doctors,
            filterKey: sp.filterKey,
          ));
        }
      }
    }

    if (scope.allowsDoctors) {
      for (final d in doctors) {
        out.add(_SearchResult(
          d.name,
          Icons.medical_services,
          subtitle: d.specialization,
          doctorId: d.id,
        ));
      }
    }
    return out.take(20).toList();
  }

  void _onResultTap(BuildContext context, _SearchResult r) {
    if (r.doctorId != null) {
      context.push('/doctors/${r.doctorId}');
      return;
    }
    if (r.filterKey != null) {
      context.push('${RouteNames.doctors}?speciality=${Uri.encodeComponent(r.filterKey!)}');
      return;
    }
    if (r.tab != null) {
      context.push('${r.route}?tab=${r.tab}');
    } else if (r.route != null) {
      context.push(r.route!);
    }
  }
}

class _SearchResult {
  _SearchResult(
    this.title,
    this.icon, {
    this.subtitle,
    this.route,
    this.tab,
    this.doctorId,
    this.filterKey,
  });
  final String title;
  final IconData icon;
  final String? subtitle;
  final String? route;
  final String? tab;
  final String? doctorId;
  final String? filterKey;
}
