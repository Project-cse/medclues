import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/blood_bank_model.dart';
import '../../services/api_service.dart';
import '../../services/blood_bank_service.dart';
import '../../utils/theme_context.dart';
import '../../widgets/cards/blood_bank_card.dart';
import '../../widgets/skeleton/list_card_skeleton.dart';

final bloodBankServiceProvider =
    Provider<BloodBankService>((ref) => BloodBankService(ref.watch(apiServiceProvider)));

final bloodBanksListProvider = FutureProvider.autoDispose<List<BloodBankModel>>((ref) {
  return ref.watch(bloodBankServiceProvider).fetchAll();
});

/// Blood banks only — no labs tab.
class BloodBanksListScreen extends ConsumerWidget {
  const BloodBanksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bloodBanksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blood Banks',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: 5,
          itemBuilder: (_, __) => const ListCardSkeleton(height: 130),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.secondaryText),
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No blood banks found',
                style: GoogleFonts.poppins(color: context.secondaryText),
              ),
            );
          }
          return RefreshIndicator(
            color: context.cs.primary,
            onRefresh: () async => ref.invalidate(bloodBanksListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              itemBuilder: (_, i) => BloodBankCard(bank: list[i]),
            ),
          );
        },
      ),
    );
  }
}
