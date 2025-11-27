// lib/modules/user/models/payment_intent_model.dart

class PaymentIntentModel {
  final String id;
  final String userId;
  final double totalAmount;
  final double originalAmount;
  final double discount;
  final double shippingFee;
  final String? voucherCode;
  final String paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic> shippingAddress;
  final DateTime expiresAt;
  final String? transactionId;

  PaymentIntentModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.originalAmount,
    required this.discount,
    required this.shippingFee,
    this.voucherCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.expiresAt,
    this.transactionId,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      shippingFee: (json['shippingFee'] ?? 0).toDouble(),
      voucherCode: json['voucherCode'],
      paymentMethod: json['paymentMethod'] ?? 'cod',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      shippingAddress: json['shippingAddress'] ?? {},
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(minutes: 30)),
      transactionId: json['transactionId'],
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isFailed => paymentStatus == 'failed';
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}