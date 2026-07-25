import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../data/symptom_specialty_map.dart';
import '../../models/doctor_model.dart';
import '../../models/hospital_model.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../utils/symptom_search.dart';
import '../../utils/theme_context.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/avatar_image.dart';

/// Search doctors & hospitals by symptom / condition (e.g. fever).
class SymptomSearchScreen extends ConsumerStatefulWidget {
  const SymptomSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SymptomSearchScreen> createState() => _SymptomSearchScreenState();
}

class _SymptomSearchScreenState extends ConsumerState<SymptomSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _search.text = initial;
      _query = initial;
    }
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _query = _search.text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(allDoctorsProvider);
    final hospitalsAsync = ref.watch(hospitalsListProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'By symptom',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              autofocus: widget.initialQuery == null,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(fontSize: 15, color: context.primaryText),
              decoration: InputDecoration(
                hintText: 'Search fever, cold, headache…',
                hintStyle: GoogleFonts.inter(color: context.hintText, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: context.secondaryText),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.logoTeal, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popularSymptomChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final chip = popularSymptomChips[i];
                final selected = _query.toLowerCase() == chip.toLowerCase();
                return FilterChip(
                  label: Text(chip, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  selected: selected,
                  onSelected: (_) {
                    _search.text = chip;
                    setState(() => _query = chip);
                  },
                  selectedColor: AppColors.logoTeal.withValues(alpha: 0.18),
                  checkmarkColor: AppColors.logoTeal,
                  side: BorderSide(
                    color: selected ? AppColors.logoTeal : context.borderColor,
                  ),
                  backgroundColor: context.cardColor,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: context.cardColor,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.logoTeal,
              unselectedLabelColor: context.secondaryText,
              indicatorColor: AppColors.logoTeal,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Doctors'),
                Tab(text: 'Hospitals'),
              ],
            ),
          ),
          Expanded(
            child: doctorsAsync.when(
              loading: () => const AppLoader(),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (doctors) {
                return hospitalsAsync.when(
                  loading: () => const AppLoader(),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (hospitals) {
                    final outcome = _query.isEmpty
                        ? const SymptomSearchOutcome(
                            match: SymptomMatchResult(concept: null, specialties: []),
                            doctors: [],
                            hospitals: [],
                          )
                        : searchBySymptom(
                            query: _query,
                            allDoctors: doctors,
                            allHospitals: hospitals,
                          );
                    return TabBarView(
                      controller: _tabs,
                      children: [
                        _DoctorsPane(outcome: outcome, query: _query),
                        _HospitalsPane(outcome: outcome, query: _query),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchedBanner extends StatelessWidget {
  const _MatchedBanner({required this.outcome, required this.query});

  final SymptomSearchOutcome outcome;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();
    if (!outcome.match.hasMatch) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          'No specialty match for “$query”. Try fever, cold, headache, or a specialty name.',
          style: GoogleFonts.inter(fontSize: 13, color: context.secondaryText, height: 1.4),
        ),
      );
    }
    final labels = outcome.match.specialties.map(specialtyDisplayName).join(' · ');
    final concept = outcome.match.concept?.label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.logoTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.logoTeal.withValues(alpha: 0.25)),
        ),
        child: Text(
          concept != null ? 'Matched: $concept → $labels' : 'Matched specialties: $labels',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.logoTeal,
          ),
        ),
      ),
    );
  }
}

class _DoctorsPane extends StatelessWidget {
  const _DoctorsPane({required this.outcome, required this.query});

  final SymptomSearchOutcome outcome;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return _EmptyHint(
        title: 'Search by symptom',
        subtitle: 'Example: fever → General Medicine & Pediatrics doctors',
      );
    }
    final list = outcome.doctors;
    return Column(
      children: [
        _MatchedBanner(outcome: outcome, query: query),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    outcome.match.hasMatch
                        ? 'No doctors found for these specialties yet.'
                        : 'Try another symptom',
                    style: GoogleFonts.inter(color: context.secondaryText),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _DoctorTile(doctor: list[i]),
                ),
        ),
      ],
    );
  }
}

class _HospitalsPane extends StatelessWidget {
  const _HospitalsPane({required this.outcome, required this.query});

  final SymptomSearchOutcome outcome;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return _EmptyHint(
        title: 'Find related hospitals',
        subtitle: 'Hospitals linked to matching specialties or doctors',
      );
    }
    final list = outcome.hospitals;
    return Column(
      children: [
        _MatchedBanner(outcome: outcome, query: query),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    outcome.match.hasMatch
                        ? 'No related hospitals found yet.'
                        : 'Try another symptom',
                    style: GoogleFonts.inter(color: context.secondaryText),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _HospitalTile(hospital: list[i]),
                ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 48, color: context.secondaryText),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: context.primaryText),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: context.secondaryText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/doctors/${doctor.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              AvatarImage(uri: doctor.imageUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: context.primaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialization,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.logoTeal, fontWeight: FontWeight.w600),
                    ),
                    if ((doctor.hospitalName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.hospitalName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, color: context.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _HospitalTile extends StatelessWidget {
  const _HospitalTile({required this.hospital});

  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (hospital.canOpenDetails) {
            context.push('/hospitals/${hospital.id}');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: context.primaryText),
                    ),
                    if (hospital.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hospital.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, color: context.secondaryText),
                      ),
                    ],
                    if ((hospital.specialization ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hospital.specialization!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.logoTeal),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
