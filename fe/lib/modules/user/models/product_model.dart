// lib/modules/user/models/product_model.dart

class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final CategoryInfo? category;
  final int sold;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.images,
    required this.variants,
    this.category,
    this.sold = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      images: (json['images'] as List?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      variants: (json['variants'] as List?)
              ?.map((e) => ProductVariant.fromJson(e))
              .toList() ??
          [],
      category: json['category'] != null
          ? CategoryInfo.fromJson(json['category'])
          : null,
      sold: json['sold'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Getters
  double get minPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  bool get inStock {
    return variants.any((v) => v.stock > 0);
  }

  String get imageUrl {
    return images.isNotEmpty ? images.first.url : '';
  }

  String get priceDisplay {
    if (minPrice == maxPrice) {
      return '${maxPrice.toStringAsFixed(0)}đ';
    }
    return '${minPrice.toStringAsFixed(0)}đ - ${maxPrice.toStringAsFixed(0)}đ';
  }
}

// Nested classes
class ProductImage {
  final String url;
  final String publicId;

  ProductImage({required this.url, required this.publicId});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'public_id': publicId,
    };
  }
}

class ProductVariant {
  final String size;
  final String color;
  final double price;
  final int stock;

  ProductVariant({
    required this.size,
    required this.color,
    required this.price,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'color': color,
      'price': price,
      'stock': stock,
    };
  }
}

class CategoryInfo {
  final String id;
  final String name;
  final String slug;

  CategoryInfo({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
    };
  }
}