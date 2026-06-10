import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/theme_context.dart';
import '../../models/doctor_model.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/speciality_match.dart';
import '../../widgets/cards/doctor_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/list_pagination.dart';
import '../../widgets/skeleton/doctor_card_skeleton.dart';

enum _DoctorFilter { all, available, rating, experience }

/// All doctors with search + filters (matches RN /doctors + user filters).
class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key, this.speciality});

  final String? speciality;

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen> {
  final _search = TextEditingController();
  _DoctorFilter _filter = _DoctorFilter.all;
  String _searchText = '';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedSpecialityProvider.notifier).state = widget.speciality;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DoctorModel> _applyFilters(List<DoctorModel> list) {
    var out = [...list];
    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialization.toLowerCase().contains(q))
          .toList();
    }
    if (_filter == _DoctorFilter.available) {
      out = out.where((d) => d.available).toList();
    }
    switch (_filter) {
      case _DoctorFilter.rating:
        out.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case _DoctorFilter.experience:
        out.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
        break;
      case _DoctorFilter.available:
      case _DoctorFilter.all:
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(doctorsListProvider);
    final spec = widget.speciality?.trim();
    final title = spec != null && spec.isNotEmpty ? formatSpecialityTitle(spec) : context.l10n.dashboardTopDoctors;

    return Scaffold(
      appBar: AppBar(title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() {
                _searchText = v;
                _page = 0;
              }),
              decoration: InputDecoration(
                hintText: context.l10n.doctorsSearch,
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip(context.l10n.dashboardViewAll, _DoctorFilter.all),
                _chip(context.l10n.doctorsFilterAvailable, _DoctorFilter.available),
                _chip(context.l10n.doctorsFilterRating, _DoctorFilter.rating),
                _chip(context.l10n.doctorExperience, _DoctorFilter.experience),
              ],
            ),
          ),
          Expanded(
            child: doctors.when(
              data: (list) {
                final sorted = _applyFilters(list);
                if (sorted.isEmpty) return AppEmptyState(title: context.l10n.doctorsEmpty);
                final totalPages = totalPagesFor(sorted.length);
                final safePage = _page.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
                if (safePage != _page) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _page = safePage);
                  });
                }
                final pageItems = paginateSlice(sorted, safePage);
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _page = 0);
                          ref.invalidate(doctorsListProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: pageItems.length,
                          itemBuilder: (_, i) => DoctorCard(
                            doctor: pageItems[i],
                            index: safePage * kDefaultPageSize + i,
                          ),
                        ),
                      ),
                    ),
                    ListPaginationBar(
                      currentPage: safePage,
                      totalItems: sorted.length,
                      onPageChanged: (p) => setState(() => _page = p),
                    ),
                  ],
                );
              },
              loading: () => ListView.builder(
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(padding: EdgeInsets.all(16), child: DoctorCardSkeleton()),
              ),
              error: (e, _) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(doctorsListProvider)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _DoctorFilter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: selected
                ? (context.isDark ? context.cs.primary : AppColors.brandBlue)
                : context.primaryText,
          ),
        ),
        selected: selected,
        onSelected: (_) => setState(() {
          _filter = value;
          _page = 0;
        }),
        selectedColor: context.chipSelectedBg,
        backgroundColor: context.chipUnselectedBg,
        checkmarkColor: context.isDark ? context.cs.primary : AppColors.specCircleFill,
        side: BorderSide(color: context.borderColor),
      ),
    );
  }
}
