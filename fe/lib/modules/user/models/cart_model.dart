// lib/modules/user/models/cart_model.dart

class CartItemModel {
  final String id;
  final String productId;
  final int quantity;
  final String size;
  final String color;
  final ProductInfoCart product;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.size,
    required this.color,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['_id'] ?? '',
      productId: json['product']?['_id'] ?? json['product'] ?? '',
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      product: ProductInfoCart.fromJson(json['product'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'size': size,
      'color': color,
      'quantity': quantity,
    };
  }

  double get price {
    // Tìm variant price từ product
    final variant = product.variants.firstWhere(
      (v) => v.size == size && v.color == color,
      orElse: () => ProductVariantInfo(
        id: '',
        size: size,
        color: color,
        price: product.basePrice,
        stock: 0,
      ),
    );
    return variant.price;
  }

  double get subtotal => price * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      productId: productId,
      quantity: quantity ?? this.quantity,
      size: size,
      color: color,
      product: product,
    );
  }
}

class ProductInfoCart {
  final String id;
  final String name;
  final String imageUrl;
  final double basePrice;
  final List<ProductVariantInfo> variants;

  ProductInfoCart({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.variants,
  });

  factory ProductInfoCart.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List? ?? [];
    final variantsJson = json['variants'] as List? ?? [];
    
    return ProductInfoCart(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: images.isNotEmpty ? (images[0]['url'] ?? '') : '',
      basePrice: (json['price'] ?? 0).toDouble(),
      variants: variantsJson
          .map((v) => ProductVariantInfo.fromJson(v))
          .toList(),
    );
  }
}

class ProductVariantInfo {
  final String id;
  final String size;
  final String color;
  final double price;
  final int stock;

  ProductVariantInfo({
    required this.id,
    required this.size,
    required this.color,
    required this.price,
    required this.stock,
  });

  factory ProductVariantInfo.fromJson(Map<String, dynamic> json) {
    return ProductVariantInfo(
      id: json['_id'] ?? '',
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }

  String get displayName => '$size - $color';
}