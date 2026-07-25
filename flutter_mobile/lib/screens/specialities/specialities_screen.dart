import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/speciality_provider.dart';
import '../../widgets/cards/speciality_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_widget.dart';

class SpecialitiesScreen extends ConsumerWidget {
  const SpecialitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(specialitiesProvider);
    final query = ref.watch(_searchProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Specialities')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filter specialities'),
              onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: async.when(
              data: (items) {
                final filtered = query.isEmpty
                    ? items
                    : items.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
                if (filtered.isEmpty) return const AppEmptyState(title: 'No specialities found');
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => SpecialityCard(speciality: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(specialitiesProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

final _searchProvider = StateProvider<String>((_) => '');
