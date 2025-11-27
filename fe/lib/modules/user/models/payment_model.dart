// lib/modules/user/models/payment_model.dart

class PaymentResponse {
  final bool success;
  final String? paymentUrl;
  final String? txnRef;
  final String? paymentId;
  final String? message;
  final Map<String, dynamic>? debug;

  PaymentResponse({
    required this.success,
    this.paymentUrl,
    this.txnRef,
    this.paymentId,
    this.message,
    this.debug,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      paymentUrl: json['paymentUrl'],
      txnRef: json['txnRef'],
      paymentId: json['paymentId'],
      message: json['message'],
      debug: json['debug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'paymentUrl': paymentUrl,
      'txnRef': txnRef,
      'paymentId': paymentId,
      'message': message,
      'debug': debug,
    };
  }
}