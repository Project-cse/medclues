import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/payment_history_item.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/app_loader.dart';

/// Matches mobile/app/(patient)/payment-history.tsx
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'failed':
        return const Color(0xFFDC2626);
      case 'refunded':
        return const Color(0xFFEA580C);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: history.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: () => ref.invalidate(paymentHistoryProvider), child: const Text('Retry')),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('No payments yet', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(paymentHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _PaymentCard(item: items[i], statusColor: _statusColor(items[i].status)),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.item, required this.statusColor});

  final PaymentHistoryItem item;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    String? dateLabel;
    if (item.createdAt != null && item.createdAt!.isNotEmpty) {
      final parsed = DateTime.tryParse(item.createdAt!);
      dateLabel = parsed != null ? DateFormat.yMMMd().add_jm().format(parsed.toLocal()) : item.createdAt;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.doctorName ?? 'Consultation',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              Text(
                item.status.toUpperCase(),
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
          if (item.publicId != null && item.publicId!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Payment ID · ${item.publicId!.toUpperCase()}',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.logoTeal),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '₹${item.displayAmount.toStringAsFixed(item.displayAmount.truncateToDouble() == item.displayAmount ? 0 : 2)}',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (item.paymentId != null && item.paymentId!.isNotEmpty)
            Text('Payment: ${item.paymentId}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
          if (dateLabel != null)
            Text(dateLabel, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
