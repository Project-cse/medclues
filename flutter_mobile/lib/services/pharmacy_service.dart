import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../utils/json_parser.dart';
import 'api_service.dart';

class PharmacyService {
  PharmacyService(this._api);

  final ApiService _api;

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is Map && data['success'] == true) {
      return unwrapList(data['data']);
    }
    throw Exception(
      data is Map ? (data['message'] ?? 'Request failed') : 'Request failed',
    );
  }

  Map<String, dynamic> _map(dynamic data, [String fallback = 'Failed']) {
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw Exception(data is Map ? (data['message'] ?? fallback) : fallback);
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final res = await _api.get('/api/user/pharmacy/prescriptions');
    return _list(res.data);
  }

  Future<List<Map<String, dynamic>>> searchMedicines([String query = '']) async {
    try {
      final res = await _api.get('/api/user/pharmacy/search', queryParameters: {'query': query});
      return _list(res.data);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final res = await _api.get('/api/user/pharmacy/orders');
    return _list(res.data);
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final res = await _api.get('/api/user/pharmacy/payments');
    return _list(res.data);
  }

  Future<Map<String, dynamic>> getOrder(int orderId) async {
    final res = await _api.get('/api/user/pharmacy/orders/$orderId');
    return _map(res.data, 'Order not found');
  }

  Future<Map<String, dynamic>> checkAvailability({
    required int consultationId,
    required int pharmacyId,
  }) async {
    final res = await _api.post('/api/user/pharmacy/availability', data: {
      'consultationId': consultationId,
      'pharmacyId': pharmacyId,
    });
    return _map(res.data, 'Availability check failed');
  }

  Future<Map<String, dynamic>> placeOrder({
    required int consultationId,
    required int pharmacyId,
    String fulfillment = 'pickup',
    String? deliveryAddress,
    String? notes,
  }) async {
    final res = await _api.post('/api/user/pharmacy/orders', data: {
      'consultationId': consultationId,
      'pharmacyId': pharmacyId,
      'fulfillment': fulfillment,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (notes != null) 'notes': notes,
    });
    return _map(res.data, 'Could not place order');
  }

  Future<void> cancelOrder(int orderId, {String? reason}) async {
    final res = await _api.post(
      '/api/user/pharmacy/orders/$orderId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    final data = res.data;
    if (data is Map && data['success'] == true) return;
    throw Exception(data is Map ? (data['message'] ?? 'Cancel failed') : 'Failed');
  }

  Future<Map<String, dynamic>> refillOrder(int orderId) async {
    final res = await _api.post('/api/user/pharmacy/orders/$orderId/refill');
    return _map(res.data, 'Refill failed');
  }

  Future<Map<String, dynamic>> createPayment(int orderId) async {
    final res = await _api.post('/api/user/pharmacy/orders/$orderId/pay');
    return _map(res.data, 'Could not start payment');
  }

  Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _api.post(
      '/api/user/pharmacy/orders/$orderId/pay/verify',
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return _map(res.data, 'Payment verification failed');
  }

  Future<Uint8List> downloadInvoicePdf(int orderId) async {
    final res = await _api.dio.get<List<int>>(
      '/api/user/pharmacy/orders/$orderId/invoice.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = res.data;
    if (data == null || data.isEmpty) {
      throw Exception('Invoice PDF unavailable');
    }
    return Uint8List.fromList(data);
  }
}
