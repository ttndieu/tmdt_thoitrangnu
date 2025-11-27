// lib/modules/admin/products/products_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

import '../common/common_table.dart';
import '../common/common_confirm.dart';
import '../common/common_notify.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  static ProductsPageState? instance;

  List products = [];
  List original = [];
  List categories = [];

  String keyword = "";
  String selectedCategory = "";

  /// 🔥 NEW — dùng để nhớ filter category khi trang mới load vào
  static String pendingCategory = "";

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

  // ================= LOAD API =================
  Future<void> load() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    final res = await admin.api.get("/api/products");
    final cate = await admin.api.get("/api/category");

    original = List.from(res.data["products"]);
    products = List.from(original);

    if (cate.data["data"] is List) {
      categories = cate.data["data"];
    }

    // 🔥 Khi trang được mở từ CategoriesPage → apply filter sau khi load xong
    if (pendingCategory.isNotEmpty) {
      selectedCategory = pendingCategory;
      pendingCategory = "";
      _applyFilter();
    }

    if (mounted) setState(() {});
  }

  void reload() => setState(() => loader = load());

  // ================= FILTER =================

  void filterKeyword(String q) {
    keyword = q.toLowerCase().trim();
    _applyFilter();
  }

  void filter(String q) => filterKeyword(q);

  /// 🔥 FIX: nếu original chưa có data → ghi nhớ slug lại
  void filterByCategory(String? slug) {
    final s = slug ?? "";

    if (original.isEmpty) {
      pendingCategory = s;
      return;
    }

    selectedCategory = s;
    _applyFilter();
  }

  void _applyFilter() {
    products = original.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      final matchName = keyword.isEmpty || name.contains(keyword);

      final cat = p["category"];
      final slug = cat is Map ? cat["slug"] : "";
      final matchCate = selectedCategory.isEmpty || slug == selectedCategory;

      return matchName && matchCate;
    }).toList();

    if (mounted) setState(() {});
  }

  // ================= IMAGE =================
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

    final columns = isNarrow
        ? ["Ảnh", "Tên", "Hành động"]
        : ["Ảnh", "Tên", "Danh mục", "Hành động"];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          final admin = Provider.of<AdminProvider>(context, listen: false);
          admin.openProductForm();
        },
      ),
      body: FutureBuilder(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = products.map<List<dynamic>>((p) {
            final img = _img(p);
            final category = p["category"] is Map ? p["category"]["name"] : "";
            final admin = Provider.of<AdminProvider>(context, listen: false);

            final full = [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  img,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
              p["name"] ?? "",
              category ?? "",
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => admin.openProductDetail(p["_id"]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => admin.openProductForm(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: "Xóa sản phẩm?",
                        message: "Bạn có chắc muốn xóa '${p["name"]}' không?",
                        confirmColor: Colors.red,
                        confirmText: "Xóa",
                      );
                      if (!ok) return;

                      final api = Provider.of<AdminProvider>(context, listen: false);
                      await api.api.delete("/api/products/${p['_id']}");

                      reload();
                      showSuccess(context, "Đã xóa sản phẩm");
                    },
                  ),
                ],
              ),
            ];

            if (isNarrow) return [full[0], full[1], full[3]];
            return full;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===================== FILTER CATEGORY BUTTON =====================
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedCategory.isEmpty ? null : selectedCategory,
                      hint: const Text("Tất cả danh mục"),
                      items: [
                        const DropdownMenuItem(
                          value: "",
                          child: Text("Tất cả danh mục"),
                        ),
                        ...categories.map((c) {
                          return DropdownMenuItem(
                            value: c["slug"],
                            child: Text(c["name"]),
                          );
                        }),
                      ],
                      onChanged: filterByCategory,
                    ),

                    if (selectedCategory.isNotEmpty)
                      TextButton(
                        onPressed: () => filterByCategory(""),
                        child: const Text("Xóa lọc"),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===================== TABLE =====================
                Expanded(
                  child: CommonTable(columns: columns, rows: rows),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
