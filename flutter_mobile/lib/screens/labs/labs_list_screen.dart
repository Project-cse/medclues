import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/lab_model.dart';
import '../../services/api_service.dart';
import '../../services/lab_service.dart';
import '../../utils/theme_context.dart';
import '../../widgets/common/avatar_image.dart';
import '../../widgets/skeleton/list_card_skeleton.dart';

final labServiceProvider = Provider<LabService>((ref) => LabService(ref.watch(apiServiceProvider)));

final labsListProvider = FutureProvider.autoDispose<List<LabModel>>((ref) {
  return ref.watch(labServiceProvider).fetchAll();
});

const _testTypes = [
  'All Tests',
  'Blood Test',
  'Full Body Checkup',
  'Diabetes Profile',
  'Thyroid Test',
  'MRI',
  'CT Scan',
  'X-Ray',
  'Ultrasound',
  'ECG',
  'Lipid Profile',
  'Vitamin D Test',
  'Urine Analysis',
];

/// Labs only — search + test type filter (matches web LabFilters.jsx).
class LabsListScreen extends ConsumerStatefulWidget {
  const LabsListScreen({super.key});

  @override
  ConsumerState<LabsListScreen> createState() => _LabsListScreenState();
}

class _LabsListScreenState extends ConsumerState<LabsListScreen> {
  final _search = TextEditingController();
  String _testType = 'All Tests';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<LabModel> _filter(List<LabModel> labs) {
    final q = _search.text.trim().toLowerCase();
    return labs.where((lab) {
      final matchesSearch = q.isEmpty ||
          lab.name.toLowerCase().contains(q) ||
          lab.address.toLowerCase().contains(q) ||
          lab.availableTests.any((t) => t.toLowerCase().contains(q));

      if (_testType == 'All Tests') return matchesSearch;

      final testKey = _testType.toLowerCase();
      final hasTest = lab.availableTests.any(
        (t) => t.toLowerCase().contains(testKey) || testKey.contains(t.toLowerCase()),
      );
      return matchesSearch && hasTest;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(labsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Labs', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _filtersBar(context),
          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: 5,
                itemBuilder: (_, __) => const ListCardSkeleton(),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(e.toString(), style: TextStyle(color: context.secondaryText)),
                ),
              ),
              data: (labs) {
                final filtered = _filter(labs);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No labs match your filters',
                      style: GoogleFonts.poppins(color: context.secondaryText),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: context.cs.primary,
                  onRefresh: () async => ref.invalidate(labsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _labCard(context, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 14, color: context.primaryText),
            decoration: InputDecoration(
              hintText: 'Search for labs or health tests...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.hintText),
              prefixIcon: Icon(Icons.search, color: context.secondaryText, size: 22),
              filled: true,
              fillColor: context.isDark ? const Color(0xFF1A1A1A) : context.cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TEST TYPE',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: context.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _testType,
            isExpanded: true,
            dropdownColor: context.cardColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.isDark ? const Color(0xFF1A1A1A) : context.cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
            items: _testTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _testType = v ?? 'All Tests'),
          ),
        ],
      ),
    );
  }

  Widget _labCard(BuildContext context, LabModel lab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarImage(uri: lab.imageUrl, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lab.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lab.address,
                  style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                ),
                if (lab.availableTests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tests: ${lab.availableTests.take(4).join(', ')}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.cs.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  lab.isOpen ? 'Open now' : 'Closed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: lab.isOpen ? const Color(0xFF16A34A) : context.cs.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
