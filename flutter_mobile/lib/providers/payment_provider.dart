import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_history_item.dart';
import 'service_providers.dart';

final paymentHistoryProvider = FutureProvider.autoDispose<List<PaymentHistoryItem>>((ref) {
  return ref.watch(paymentServiceProvider).getPaymentHistory();
});
