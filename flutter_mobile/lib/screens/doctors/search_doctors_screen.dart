import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/storage_helper.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/cards/doctor_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/skeleton/doctor_card_skeleton.dart';

class SearchDoctorsScreen extends ConsumerStatefulWidget {
  const SearchDoctorsScreen({super.key});

  @override
  ConsumerState<SearchDoctorsScreen> createState() => _SearchDoctorsScreenState();
}

class _SearchDoctorsScreenState extends ConsumerState<SearchDoctorsScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(FocusNode()));
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value);
      if (value.trim().isNotEmpty) {
        ref.read(storageHelperProvider).addRecentSearch(value.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = _query.isEmpty ? null : ref.watch(doctorSearchProvider(_query));
    final recent = ref.watch(storageHelperProvider).getRecentSearches();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.doctorsSearch, border: InputBorder.none),
          onChanged: _onChanged,
        ),
      ),
      body: _query.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(l10n.doctorsRecentSearches, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                ...recent.map((q) => ListTile(title: Text(q), onTap: () {
                      _controller.text = q;
                      _onChanged(q);
                    })),
              ],
            )
          : results!.when(
              data: (docs) => docs.isEmpty
                  ? AppEmptyState(title: l10n.doctorsNoResults)
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, i) => DoctorCard(doctor: docs[i], index: i),
                    ),
              loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, __) => const DoctorCardSkeleton(),
                  ),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
    );
  }
}
