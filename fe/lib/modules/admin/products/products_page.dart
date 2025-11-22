import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import 'product_item_card.dart';
import 'product_form_page.dart';
import 'product_detail_admin.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  static ProductsPageState? instance;

  List<dynamic> products = [];
  List<dynamic> originalProducts = []; // ← lưu bản gốc để filter
  late Future<void> loader;

  @override
  void initState() {
    super.initState();
    instance = this;
    loader = _loadProducts();
  }

  // -----------------------------
  // LOAD PRODUCTS
  // -----------------------------
  Future<void> _loadProducts() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final resp = await admin.api.get("/api/products");

    setState(() {
      originalProducts = List.from(resp.data["products"]);
      products = List.from(originalProducts);
    });
  }

  // -----------------------------
  // FILTER FOR SEARCH BAR
  // -----------------------------
  void filter(String query) {
    setState(() {
      if (query.isEmpty) {
        products = List.from(originalProducts);
      } else {
        final lower = query.toLowerCase();
        products = originalProducts.where((p) {
          final name = (p["name"] ?? "").toString().toLowerCase();
          return name.contains(lower);
        }).toList();
      }
    });
  }

  void reload() => setState(() => loader = _loadProducts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sản phẩm")),
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
      body: FutureBuilder(
        future: loader,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (products.isEmpty) {
            return const Center(child: Text("Không có sản phẩm"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = products[i];
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
                onDelete: () async {
                  final admin =
                      Provider.of<AdminProvider>(context, listen: false);
                  await admin.api.delete("/api/products/${p['_id']}");
                  reload();
                },
                onView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailAdmin(productId: p["_id"]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
