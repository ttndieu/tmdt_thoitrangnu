// lib/modules/admin/products/product_detail_admin.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class ProductDetailAdmin extends StatefulWidget {
  final String productId;
  const ProductDetailAdmin({super.key, required this.productId});

  @override
  State<ProductDetailAdmin> createState() => _ProductDetailAdminState();
}

class _ProductDetailAdminState extends State<ProductDetailAdmin> {
  Map<String, dynamic>? _product;
  bool _loading = true;

  Future<void> _load() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final resp = await admin.api.get("/api/products/${widget.productId}");

    if (resp.data is Map && resp.data.containsKey("product")) {
      setState(() => _product = Map<String, dynamic>.from(resp.data["product"]));
    }

    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== NÚT QUAY LẠI =====================
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    final admin = Provider.of<AdminProvider>(context, listen: false);
                    admin.backToProducts();
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Chi tiết sản phẩm",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ===================== NỘI DUNG CHI TIẾT =====================
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _product == null
                      ? const Center(child: Text("Không tìm thấy sản phẩm"))
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// ======================== CONTENT BUILDER ========================
  Widget _buildContent() {
    return ListView(
      children: [
        // Tên sản phẩm
        Text(
          _product!["name"] ?? "",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        // Danh mục
        Text(
          "Danh mục: ${_product!["category"]?["name"] ?? ""}",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 20),

        // Ảnh sản phẩm
        if ((_product!["images"] as List).isNotEmpty)
          SizedBox(
            height: 170,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final img in (_product!["images"] as List))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img is Map ? img["url"] ?? "" : img.toString(),
                        width: 170,
                        height: 170,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Mô tả
        Text(
          "Mô tả:",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _product!["description"] ?? "",
          style: const TextStyle(fontSize: 15),
        ),

        const SizedBox(height: 20),

        // Variants
        const Text(
          "Variants",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Column(
          children: [
            for (final v in (_product!["variants"] as List<dynamic>))
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text("${v["size"] ?? ""} - ${v["color"] ?? ""}"),
                  subtitle: Text(
                    "Stock: ${v["stock"]}   |   Price: ${v["price"]}₫",
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
