class VoucherModel {
  final String id;
  final String code;
  final double discountPercent;
  final double maxDiscount;
  final double minOrderValue;
  final int quantity;
  final bool active;
  final DateTime expiredAt;

  VoucherModel({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.quantity,
    required this.active,
    required this.expiredAt,
  });

  String get title {
    if (discountPercent > 0) {
      return 'GIẢM ${discountPercent.toInt()}%';
    }
    return 'VOUCHER';
  }

  String get displayDescription {
    if (minOrderValue > 0) {
      return 'Đơn tối thiểu ${_formatPrice(minOrderValue)}';
    }
    return 'Không giới hạn đơn hàng';
  }

  bool get isExpired {
    return expiredAt.isBefore(DateTime.now());
  }

  bool get isAvailable {
    return active && !isExpired && quantity > 0;
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      maxDiscount: (json['maxDiscount'] ?? 0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      active: json['active'] ?? true,
      expiredAt: DateTime.parse(json['expiredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'discountPercent': discountPercent,
      'maxDiscount': maxDiscount,
      'minOrderValue': minOrderValue,
      'quantity': quantity,
      'active': active,
      'expiredAt': expiredAt.toIso8601String(),
    };
  }
}