class ProductModel {
  final String id;
  final String name;
  final int price;
  final List<String> images;
  final String? description;
  final String? category;
  final int? sold;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    this.description,
    this.category,
    this.sold,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      price: json["price"] ?? 0,
      images: json["images"] != null
          ? List<String>.from(json["images"])
          : <String>[],
      description: json["description"],
      category: json["category"] is Map
          ? json["category"]["name"]
          : json["category"],
      sold: json["sold"] ?? 0,
    );
  }
}
