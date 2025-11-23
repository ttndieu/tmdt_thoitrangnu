// lib/modules/user/models/voucher_model.dart

class VoucherModel {
  final String id;
  final String code;
  final int discountPercent;
  final double maxDiscount;
  final double minOrderValue;
  final int quantity;
  final DateTime expiredAt;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoucherModel({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.quantity,
    required this.expiredAt,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountPercent: json['discountPercent'] ?? 0,
      maxDiscount: (json['maxDiscount'] ?? 0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      expiredAt: DateTime.parse(json['expiredAt']),
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
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
      'expiredAt': expiredAt.toIso8601String(),
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // ✅ Helpers
  bool get isExpired => DateTime.now().isAfter(expiredAt);
  bool get isAvailable => active && !isExpired && quantity > 0;
  
  String get discountText {
    if (discountPercent > 0) {
      return 'GIẢM $discountPercent%';
    }
    return 'GIẢM ${maxDiscount.toStringAsFixed(0)}đ';
  }

  String get conditionText {
    if (minOrderValue > 0) {
      return 'Đơn tối thiểu ${minOrderValue.toStringAsFixed(0)}đ';
    }
    return 'Không có điều kiện';
  }

  String get expiryText {
    final now = DateTime.now();
    final difference = expiredAt.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    } else if (difference.inDays > 7) {
      return 'HSD: ${expiredAt.day}/${expiredAt.month}/${expiredAt.year}';
    } else if (difference.inDays > 0) {
      return 'Còn ${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return 'Còn ${difference.inHours} giờ';
    } else {
      return 'Còn ${difference.inMinutes} phút';
    }
  }

  double calculateDiscount(double totalAmount) {
    if (!isAvailable || totalAmount < minOrderValue) {
      return 0;
    }
    
    final discountAmount = (totalAmount * discountPercent) / 100;
    return discountAmount > maxDiscount ? maxDiscount : discountAmount;
  }

  VoucherModel copyWith({
    String? id,
    String? code,
    int? discountPercent,
    double? maxDiscount,
    double? minOrderValue,
    int? quantity,
    DateTime? expiredAt,
    bool? active,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      quantity: quantity ?? this.quantity,
      expiredAt: expiredAt ?? this.expiredAt,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}