// lib/modules/user/models/order_model.dart

class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final ShippingAddress shippingAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ THÊM VOUCHER FIELDS
  final String? voucherCode;
  final double? discount;
  final double? originalAmount;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.createdAt,
    required this.updatedAt,
    this.voucherCode,        // ✅ NULLABLE
    this.discount,           // ✅ NULLABLE
    this.originalAmount,     // ✅ NULLABLE
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cod',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      // ✅ PARSE VOUCHER FIELDS
      voucherCode: json['voucherCode'],
      discount: json['discount'] != null 
          ? (json['discount'] as num).toDouble() 
          : null,
      originalAmount: json['originalAmount'] != null
          ? (json['originalAmount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'shippingAddress': shippingAddress.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // ✅ ADD VOUCHER FIELDS
      if (voucherCode != null) 'voucherCode': voucherCode,
      if (discount != null) 'discount': discount,
      if (originalAmount != null) 'originalAmount': originalAmount,
    };
  }

  // Getters
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod.toLowerCase()) {
      case 'cod':
        return 'Thanh toán khi nhận hàng';
      case 'momo':
        return 'Ví MoMo';
      case 'vnpay':
        return 'VNPAY';
      default:
        return paymentMethod;
    }
  }

  bool get canCancel {
    return status == 'pending' || status == 'confirmed';
  }
  
  // CHECK NẾU CÓ VOUCHER
  bool get hasVoucher {
    return voucherCode != null && 
           voucherCode!.isNotEmpty && 
           discount != null && 
           discount! > 0;
  }
}

// OrderItem Model
class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final String size;
  final String color;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.color,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle nested product object
    final product = json['product'] is Map ? json['product'] : {};
    final images = product['images'] is List ? product['images'] : [];
    
    return OrderItem(
      id: json['_id'] ?? '',
      productId: json['productId'] ?? product['_id'] ?? '',
      productName: json['name'] ?? product['name'] ?? '',
      imageUrl: images.isNotEmpty 
          ? (images[0]['url'] ?? '') 
          : '',
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'name': productName,
      'imageUrl': imageUrl,
      'size': size,
      'color': color,
      'quantity': quantity,
      'price': price,
    };
  }

  double get subtotal => price * quantity;
}

// ShippingAddress Model
class ShippingAddress {
  final String fullName;
  final String phone;
  final String addressLine;
  final String ward;
  final String district;
  final String city;

  ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.ward,
    required this.district,
    required this.city,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['addressLine'] ?? '',
      ward: json['ward'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine': addressLine,
      'ward': ward,
      'district': district,
      'city': city,
    };
  }

  String get fullAddress {
    return '$addressLine, $ward, $district, $city';
  }
}