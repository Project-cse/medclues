import '../config/api_config.dart';
import '../models/payment_history_item.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class PaymentOrderResult {
  const PaymentOrderResult({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.razorpayKey,
    required this.checkoutToken,
    required this.appointmentId,
  });

  final String orderId;
  final int amount;
  final String currency;
  final String razorpayKey;
  final String checkoutToken;
  final String appointmentId;
}

class PaymentService {
  PaymentService(this._api);

  final ApiService _api;

  Future<List<PaymentHistoryItem>> getPaymentHistory() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.paymentsHistory);
    final data = res.data ?? {};
    assertSuccess(data);
    final list = data['payments'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => PaymentHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> getRazorpayKey() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.paymentsRazorpayKey);
    final data = res.data ?? {};
    assertSuccess(data);
    return '${data['key_id'] ?? ''}';
  }

  Future<PaymentOrderResult> createAppointmentOrder({
    required int amountPaise,
    required String doctorId,
    required String appointmentDate,
    required String appointmentTime,
    String visitType = 'online',
    String? notes,
    int? slotId,
    String? slotType,
    String mode = 'online',
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.paymentsCreateOrder,
      data: {
        'amount': amountPaise,
        'doctor_id': doctorId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'visit_type': visitType,
        'mode': mode,
        if (notes != null) 'notes': notes,
        if (slotId != null) 'slot_id': slotId,
        if (slotType != null) 'slot_type': slotType,
      },
    );
    final data = res.data ?? {};
    final orderId = data['order_id']?.toString();
    final razorpayKey = data['razorpay_key']?.toString();
    final checkoutToken = data['checkout_token']?.toString();
    if (orderId == null ||
        orderId.isEmpty ||
        razorpayKey == null ||
        razorpayKey.isEmpty ||
        checkoutToken == null ||
        checkoutToken.isEmpty) {
      throw Exception(data['message']?.toString() ?? 'Failed to create payment order');
    }
    return PaymentOrderResult(
      orderId: orderId,
      amount: (data['amount'] as num?)?.toInt() ?? amountPaise,
      currency: '${data['currency'] ?? 'INR'}',
      razorpayKey: razorpayKey,
      checkoutToken: checkoutToken,
      appointmentId: '${data['appointment_id'] ?? ''}',
    );
  }

  String checkoutUrl(String checkoutToken) {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${ApiConfig.paymentsCheckout(checkoutToken)}';
  }

  Future<Map<String, dynamic>> verifyAppointmentPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String? appointmentId,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.paymentsVerify,
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        if (appointmentId != null) 'appointment_id': appointmentId,
      },
    );
    final data = res.data ?? {};
    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Payment verification failed');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> recordFailedPayment({
    required String orderId,
    required String appointmentId,
    required String error,
  }) async {
    await _api.post<Map<String, dynamic>>(
      ApiConfig.paymentsFailed,
      data: {
        'order_id': orderId,
        'appointment_id': appointmentId,
        'error': error,
      },
    );
  }

  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.paymentsStatus(orderId));
    final data = res.data ?? {};
    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Could not check payment status');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> confirmPaidOrder(String orderId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.paymentsConfirmOrder,
      data: {'order_id': orderId},
    );
    final data = res.data ?? {};
    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Could not confirm payment');
    }
    return Map<String, dynamic>.from(data);
  }
}
