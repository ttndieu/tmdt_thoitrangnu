// lib/modules/admin/products/product_item_card.dart
import 'package:flutter/material.dart';

typedef VoidCallbackAsync = Future<void> Function();

class ProductItemCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallbackAsync? onEdit;
  final VoidCallbackAsync? onDelete;
  final VoidCallbackAsync? onView;

  const ProductItemCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  String _firstImageUrl() {
    final imgs = product["images"];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map && first.containsKey("url")) return first["url"] ?? "";
      if (first is String) return first;
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _firstImageUrl();
    final categoryName = (product["category"] is Map) ? (product["category"]["name"] ?? "") : "";

    return Card(
      elevation: 2,
      child: ListTile(
        onTap: () async {
          if (onView != null) await onView!();
        },
        leading: imageUrl.isNotEmpty
            ? Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
            : const SizedBox(width: 64, height: 64, child: Icon(Icons.image)),
        title: Text(product["name"] ?? "Unnamed"),
        subtitle: Text("Danh mục: $categoryName\nVariants: ${(product["variants"] as List?)?.length ?? 0}"),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.visibility), onPressed: onView != null ? () => onView!() : null),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit != null ? () => onEdit!() : null),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete != null ? () => onDelete!() : null),
          ],
        ),
      ),
    );
  }
}
