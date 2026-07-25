import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../models/payment_history_item.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/app_loader.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'How to Pay'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PaymentHistoryTab(),
            _PaymentInfoTab(),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryTab extends ConsumerWidget {
  const _PaymentHistoryTab();

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

    return history.when(
      loading: () => const AppLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(paymentHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No payments yet',
              style: GoogleFonts.poppins(color: context.secondaryText),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(paymentHistoryProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PaymentCard(
              item: items[i],
              statusColor: _statusColor(items[i].status),
            ),
          ),
        );
      },
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
      dateLabel = parsed != null
          ? DateFormat.yMMMd().add_jm().format(parsed.toLocal())
          : item.createdAt;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.doctorName ?? 'Consultation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText,
                  ),
                ),
              ),
              Text(
                item.status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${item.displayAmount.toStringAsFixed(item.displayAmount.truncateToDouble() == item.displayAmount ? 0 : 2)}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (item.paymentId != null && item.paymentId!.isNotEmpty)
            Text(
              'Payment: ${item.paymentId}',
              style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
            ),
          if (dateLabel != null)
            Text(
              dateLabel,
              style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
            ),
        ],
      ),
    );
  }
}

class _PaymentInfoTab extends StatelessWidget {
  const _PaymentInfoTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card_outlined, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Payment Methods',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Online consultations use Razorpay at booking time. In-clinic visits can be paid at hospital reception, or paid online via Razorpay when that option is offered at booking.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
