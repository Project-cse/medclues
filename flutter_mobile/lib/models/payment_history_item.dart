class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    this.publicId,
    required this.status,
    this.orderId,
    this.paymentId,
    this.appointmentId,
    this.doctorName,
    this.amountInr,
    this.amountPaise,
    this.error,
    this.createdAt,
  });

  final String id;
  final String? publicId;
  final String? orderId;
  final String? paymentId;
  final String? appointmentId;
  final String? doctorName;
  final double? amountInr;
  final int? amountPaise;
  final String status;
  final String? error;
  final String? createdAt;

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      publicId: (json['publicId'] ?? json['public_id'])?.toString(),
      orderId: (json['order_id'] ?? json['orderId'])?.toString(),
      paymentId: (json['payment_id'] ?? json['paymentId'])?.toString(),
      appointmentId:
          (json['appointment_id'] ?? json['appointmentId'])?.toString(),
      doctorName: (json['doctor_name'] ?? json['doctorName'])?.toString(),
      amountInr: ((json['amount_inr'] ?? json['amountInr']) as num?)
          ?.toDouble(),
      amountPaise: ((json['amount_paise'] ?? json['amountPaise']) as num?)
          ?.toInt(),
      status: '${json['status'] ?? 'unknown'}',
      error: json['error']?.toString(),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
    );
  }

  double get displayAmount {
    if (amountInr != null) return amountInr!;
    if (amountPaise != null) return amountPaise! / 100;
    return 0;
  }
}
