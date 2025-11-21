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
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Product detail")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text("Không tìm thấy sản phẩm"))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListView(
                    children: [
                      Text(_product!["name"] ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Danh mục: ${_product!["category"]?["name"] ?? ""}"),
                      const SizedBox(height: 12),
                      if ((_product!["images"] as List).isNotEmpty)
                        SizedBox(
                          height: 160,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final img in (_product!["images"] as List))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.network(img is Map ? img["url"] ?? "" : (img.toString()), width: 160, height: 160, fit: BoxFit.cover),
                                )
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text("Mô tả: ${_product!["description"] ?? ""}"),
                      const SizedBox(height: 12),
                      const Text("Variants", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          for (final v in (_product!["variants"] as List<dynamic>))
                            Card(
                              child: ListTile(
                                title: Text("${v["size"]} - ${v["color"]}"),
                                subtitle: Text("Stock: ${v["stock"]}, Price: ${v["price"]}"),
                              ),
                            )
                        ],
                      )
                    ],
                  ),
                ),
    );
  }
}
