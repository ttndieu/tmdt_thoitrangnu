// lib/modules/admin/products/products_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import 'product_item_card.dart';
import 'product_form_page.dart';
import 'product_detail_admin.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<dynamic>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = _loadProducts();
  }

  Future<List<dynamic>> _loadProducts() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final resp = await admin.api.get("/api/products");
    // backend trả { products: [...] } hoặc { product: {...} } tuỳ endpoint
    if (resp.data is Map && resp.data.containsKey("products")) {
      return List<dynamic>.from(resp.data["products"]);
    }
    // fallback
    return resp.data is List ? List<dynamic>.from(resp.data) : [];
  }

  void reload() {
    if (!mounted) return;
    setState(() {
      futureProducts = _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Products (Admin)")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          );
          reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải sản phẩm: ${snapshot.error}"));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text("Không có sản phẩm nào"));
          }

          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = products[i] as Map<String, dynamic>;
                return ProductItemCard(
                  product: p,
                  onEdit: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormPage(product: p),
                      ),
                    );
                    reload();
                  },
                  onView: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailAdmin(productId: p["_id"]),
                      ),
                    );
                    reload();
                  },
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Xác nhận"),
                        content: const Text("Bạn có muốn xoá sản phẩm này?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xoá")),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await admin.api.delete("/api/products/${p['_id']}");
                      reload();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
