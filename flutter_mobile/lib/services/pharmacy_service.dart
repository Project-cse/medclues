import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class PharmacyService {
  PharmacyService(this._api);

  final ApiService _api;

  Dio? _catalogDio;

  Dio get _catalogClient {
    return _catalogDio ??= Dio(
      BaseOptions(
        baseUrl: ApiConfig.pharmacyCatalogBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
  }

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

  List<Map<String, dynamic>> _extractInventoryList(dynamic data) {
    if (data is List) return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (data is Map) {
      for (final key in ['data', 'inventory', 'medicines', 'items', 'products']) {
        final v = data[key];
        if (v is List) {
          return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _parseMedicineList(dynamic data) {
    final list = data is List
        ? data
        : _extractInventoryList(data);
    return list.map((item) {
      final m = Map<String, dynamic>.from(item as Map);
      final price = (m['price'] is num)
          ? (m['price'] as num).toDouble()
          : (m['costPrice'] is num ? (m['costPrice'] as num).toDouble() : 0.0);
      final mrp = (m['mrp'] is num) ? (m['mrp'] as num).toDouble() : price;
      String discount = '';
      if (m['discount'] != null && m['discount'].toString().trim().isNotEmpty) {
        discount = m['discount'].toString();
      } else if (mrp > 0 && price < mrp) {
        final pct = (((1 - price / mrp) * 100).round());
        if (pct > 0) discount = '$pct% OFF';
      }
      final stock = m['stock'] is num ? (m['stock'] as num).toInt() : 0;
      return {
        'id': m['_id'] ?? m['id'] ?? 'med_${m['name']}',
        '_id': m['_id'] ?? m['id'],
        'name': m['name'] ?? 'Unnamed Medicine',
        'brand': m['brand'] ?? m['distributor'] ?? '',
        'category': m['category'] ?? 'General',
        'salt': m['salt'] ?? m['composition'] ?? '',
        'price': price,
        'mrp': mrp,
        'discount': discount,
        'requiresRx': m['requiresRx'] ?? false,
        'image': m['image'] != null ? m['image'].toString() : '',
        'stock': stock,
      };
    }).where((m) => (m['stock'] as int) > 0).toList();
  }

  /// Live master catalog from pharmacy Express inventory service.
  Future<List<Map<String, dynamic>>> searchMedicines([String query = '']) async {
    final res = await _catalogClient.get(ApiConfig.pharmacyInventory);
    final parsed = _parseMedicineList(res.data);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return parsed;
    return parsed.where((m) {
      final blob = [
        m['name'],
        m['brand'],
        m['salt'],
        m['category'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
      return blob.contains(q);
    }).toList();
  }

  Future<List<String>> getCatalogCategories() async {
    try {
      final meds = await searchMedicines();
      final cats = meds
          .map((m) => m['category']?.toString().trim() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return cats;
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

  /// Retail / home-delivery cart — no prescription required.
  Future<Map<String, dynamic>> placeCatalogOrder({
    required List<Map<String, dynamic>> items,
    String fulfillment = 'delivery',
    String paymentMethod = 'upi',
    String? deliveryAddress,
    int? pharmacyId,
    double? deliveryFee,
    String? notes,
  }) async {
    final res = await _api.post('/api/user/pharmacy/catalog-orders', data: {
      'items': items,
      'fulfillment': fulfillment,
      'paymentMethod': paymentMethod,
      if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
        'deliveryAddress': deliveryAddress.trim(),
      if (pharmacyId != null) 'pharmacyId': pharmacyId,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
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
