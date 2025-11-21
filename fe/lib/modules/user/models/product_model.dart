class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String categoryId;
  final String? categoryName;
  final String? categorySlug;
  final List<ProductVariant> variants;
  final List<String> images;
  final int sold;
  bool isFavorite;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.categoryId,
    this.categoryName,
    this.categorySlug,
    required this.variants,
    required this.images,
    this.sold = 0,
    this.isFavorite = false,
  });

  double get minPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  String get displayPrice {
    if (minPrice == maxPrice) {
      return _formatPrice(minPrice);
    }
    return '${_formatPrice(minPrice)} - ${_formatPrice(maxPrice)}';
  }

  String? get mainImage => images.isNotEmpty ? images[0] : null;

  int get totalStock {
    return variants.fold(0, (sum, variant) => sum + variant.stock);
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String catId = '';
    String? catName;
    String? catSlug;

    if (json['category'] != null) {
      if (json['category'] is String) {
        catId = json['category'];
      } else if (json['category'] is Map) {
        catId = json['category']['_id'] ?? '';
        catName = json['category']['name'];
        catSlug = json['category']['slug'];
      }
    }

    List<ProductVariant> variantsList = [];
    if (json['variants'] != null && json['variants'] is List) {
      variantsList = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v))
          .toList();
    }

    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List).map((i) => i.toString()).toList();
    }

    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      categoryId: catId,
      categoryName: catName,
      categorySlug: catSlug,
      variants: variantsList,
      images: imagesList,
      sold: json['sold'] ?? 0,
    );
  }

  ProductModel copyWith({bool? isFavorite}) {
    return ProductModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      categorySlug: categorySlug,
      variants: variants,
      images: images,
      sold: sold,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class ProductVariant {
  final String? id;
  final String size; // "S", "M", "L"
  final String color;
  final int stock;
  final double price;

  ProductVariant({
    this.id,
    required this.size,
    required this.color,
    required this.stock,
    required this.price,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['_id'],
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      stock: json['stock'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'color': color,
      'stock': stock,
      'price': price,
    };
  }
}