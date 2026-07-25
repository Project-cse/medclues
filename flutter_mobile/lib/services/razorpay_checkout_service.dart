import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

/// Opens Razorpay's native checkout UI (Android / iOS).
class RazorpayCheckoutService {
  Razorpay? _razorpay;

  Future<RazorpayCheckoutResult> openCheckout({
    required String key,
    required String orderId,
    required int amountPaise,
    String name = 'MedClues',
    String description = 'Consultation payment',
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    bool preferUpi = true,
  }) async {
    final completer = Completer<RazorpayCheckoutResult>();
    _disposeRazorpay();

    final razorpay = Razorpay();
    _razorpay = razorpay;

    void finishWithError(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
      _disposeRazorpay();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
      final paymentId = response.paymentId;
      final paidOrderId = response.orderId;
      final signature = response.signature;
      if (paymentId == null || paidOrderId == null || signature == null) {
        finishWithError(Exception('Invalid payment response from Razorpay'));
        return;
      }
      if (!completer.isCompleted) {
        completer.complete(
          RazorpayCheckoutResult(
            orderId: paidOrderId,
            paymentId: paymentId,
            signature: signature,
          ),
        );
      }
      _disposeRazorpay();
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
      String? fromError;
      final err = response.error;
      if (err is Map) {
        fromError = err['description']?.toString() ?? err['reason']?.toString();
      }
      final msg = response.message ?? fromError ?? 'Payment failed';
      finishWithError(Exception(msg));
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    final options = <String, dynamic>{
      'key': key,
      'amount': amountPaise,
      'currency': 'INR',
      'name': name,
      'description': description,
      'order_id': orderId,
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'config': {
        'display': {
          'blocks': {
            'upi': {
              'name': 'UPI — PhonePe, Google Pay, Paytm & UPI ID',
              'instruments': [
                {'method': 'upi'},
              ],
            },
          },
          'sequence': preferUpi ? ['block.upi'] : ['block.upi'],
          'preferences': {'show_default_blocks': true},
        },
      },
      'theme': {'color': '#009F93'},
    };

    final prefill = <String, String>{};
    if (customerName != null && customerName.isNotEmpty) {
      prefill['name'] = customerName;
    }
    if (customerEmail != null && customerEmail.isNotEmpty) {
      prefill['email'] = customerEmail;
    }
    if (customerPhone != null && customerPhone.isNotEmpty) {
      prefill['contact'] = customerPhone;
    }
    if (prefill.isNotEmpty) options['prefill'] = prefill;

    razorpay.open(options);
    return completer.future;
  }

  void dispose() => _disposeRazorpay();

  void _disposeRazorpay() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
