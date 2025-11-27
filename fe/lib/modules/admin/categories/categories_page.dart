// lib/modules/admin/categories/categories_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin_provider.dart';
import '../admin_routes.dart';
import '../common/common_card.dart';
import '../common/common_confirm.dart';
import '../common/common_notify.dart';
import '../common/common_gap.dart';
import '../products/products_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  static CategoriesPageState? instance;

  List categories = [];
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

  // ================= LOAD API =================
  Future<void> load() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/category");

    original = List.from(res.data["data"]);
    categories = List.from(original);

    if (mounted) setState(() {});
  }

  void reload() {
    loader = load();
    setState(() {});
  }

  // ================= FILTER USED BY HEADER SEARCH =================
  void filter(String q) {
    q = q.trim().toLowerCase();
    setState(() {
      categories = q.isEmpty
          ? List.from(original)
          : original.where((c) {
              return c["name"].toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  // ================= OPEN CREATE / UPDATE FORM =================
  Future<void> openForm({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?["name"] ?? "");

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? "Tạo danh mục" : "Cập nhật danh mục"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Tên danh mục"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // Confirm save
    final confirm = await showConfirmDialog(
      context,
      title: item == null ? "Tạo danh mục mới?" : "Cập nhật danh mục?",
      message: "Bạn muốn lưu thay đổi?",
      confirmText: "Lưu",
      confirmColor: Colors.green,
    );

    if (!confirm) return;

    try {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final body = {"name": nameCtrl.text.trim()};

      if (item == null) {
        await admin.api.post("/api/category", data: body);
        showSuccess(context, "Đã thêm danh mục");
      } else {
        await admin.api.put("/api/category/${item["_id"]}", data: body);
        showSuccess(context, "Đã cập nhật danh mục");
      }

      reload();
    } catch (e) {
      showError(context, "Lỗi: $e");
    }
  }

  // ================= BUILD CARD GRID =================
  Widget buildCards() {
    final width = MediaQuery.of(context).size.width;

    int cross = 1;
    if (width >= 900)
      cross = 3;
    else if (width >= 600)
      cross = 2;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        childAspectRatio: 3.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final c = categories[i];

        return InkWell(
          onTap: () {
            final admin = Provider.of<AdminProvider>(context, listen: false);

            // 1️⃣ chuyển sang trang sản phẩm
            admin.changeRoute(AdminRoutes.products);

            // 2️⃣ Ghi nhớ slug để ProductsPage filter khi load xong
            ProductsPageState.pendingCategory = c["slug"];
          },
          child: CommonCard(
            color: const Color(0xFFE6E8FF),
            child: Row(
              children: [
                const Icon(
                  Icons.folder,
                  size: 30,
                  color: Color.fromARGB(255, 120, 156, 222),
                ),
                G.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c["name"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // ⭐ THÊM DÒNG NÀY ⭐
                      Text(
                        "${c["count"] ?? 0} sản phẩm",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openForm(item: c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: "Xóa danh mục?",
                      message: "Bạn có chắc muốn xóa '${c["name"]}'?",
                      confirmColor: Colors.red,
                      confirmText: "Xóa",
                    );

                    if (!ok) return;

                    try {
                      final admin = Provider.of<AdminProvider>(
                        context,
                        listen: false,
                      );
                      await admin.api.delete("/api/category/${c["_id"]}");
                      showSuccess(context, "Đã xóa danh mục");
                      reload();
                    } catch (e) {
                      showError(context, "Lỗi: $e");
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categories.isEmpty) {
            return const Center(child: Text("Không có danh mục"));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: buildCards(),
          );
        },
      ),
    );
  }
}
