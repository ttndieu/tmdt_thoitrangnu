// lib/modules/admin/products/products_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

import '../common/common_table.dart';
import '../common/common_confirm.dart';
import '../common/common_notify.dart';

import 'product_form_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  static ProductsPageState? instance;

  List products = [];
  List original = [];
  late Future loader;

  @override
  void initState() {
    super.initState();
    instance = this;
    loader = load();
  }

  @override
  void dispose() {
    if (instance == this) instance = null;
    super.dispose();
  }

  Future<void> load() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/products");
    setState(() {
      original = List.from(res.data["products"]);
      products = List.from(original);
    });
  }

  void reload() => setState(() => loader = load());

  void filter(String q) {
    q = q.toLowerCase().trim();
    setState(() {
      products = q.isEmpty ? List.from(original) : original.where((p) {
        final name = (p["name"] ?? "").toString().toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  String _img(Map p) {
    final imgs = p["images"];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map) return first["url"] ?? "";
      if (first is String) return first;
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;
    final columns = isNarrow ? ["Ảnh", "Tên", "Hành động"] : ["Ảnh", "Tên", "Danh mục", "Hành động"];
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          final admin = Provider.of<AdminProvider>(context, listen: false);
          admin.openProductForm(); // open form inside admin layout
        },
      ),
      body: FutureBuilder(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (products.isEmpty) return const Center(child: Text("Không có sản phẩm"));

          final rows = products.map<List<dynamic>>((p) {
            final img = _img(p);
            final category = p["category"] is Map ? p["category"]["name"] : "";
            final admin = Provider.of<AdminProvider>(context, listen: false);

            final full = [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(img, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
              ),
              p["name"] ?? "",
              category ?? "",
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.visibility), onPressed: () => admin.openProductDetail(p["_id"])),
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => admin.openProductForm(p)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                    final ok = await showConfirmDialog(context, title: "Xóa sản phẩm?", message: "Bạn có chắc muốn xóa '${p["name"]}' không?", confirmColor: Colors.red, confirmText: "Xóa");
                    if (!ok) return;
                    final apiAdmin = Provider.of<AdminProvider>(context, listen: false);
                    await apiAdmin.api.delete("/api/products/${p['_id']}");
                    reload();
                    showSuccess(context, "Đã xóa sản phẩm");
                  }),
                ],
              ),
            ];

            if (isNarrow) return [full[0], full[1], full[3]];
            return full;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [Expanded(child: CommonTable(columns: columns, rows: rows))]),
          );
        },
      ),
    );
  }
}
