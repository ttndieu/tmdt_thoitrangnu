// lib/modules/admin/users/users_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin_provider.dart';
import '../common/common_table.dart';
import '../common/common_confirm.dart';
import '../common/common_notify.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => UsersPageState();
}

class UsersPageState extends State<UsersPage> {
  static UsersPageState? instance;

  List users = [];
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
    final res = await admin.api.get("/api/admin/users");

    setState(() {
      original = List.from(res.data["users"]);
      users = List.from(original);
    });
  }

  void reload() => setState(() => loader = load());

  void filter(String q) {
    q = q.toLowerCase();
    setState(() {
      users = q.isEmpty
          ? List.from(original)
          : original.where((u) =>
              (u["name"] ?? "").toLowerCase().contains(q) ||
              (u["email"] ?? "").toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 800;
    final columns = narrow
        ? ["Tên", "Email", "Hành động"]
        : ["Tên", "Email", "SĐT", "Vai trò", "Hành động"];

    return Scaffold(
      body: FutureBuilder(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (users.isEmpty) {
            return const Center(child: Text("Không có người dùng"));
          }

          final rows = users.map<List<dynamic>>((u) {
            final admin = Provider.of<AdminProvider>(context, listen: false);

            final actions = Row(
              children: [
                // 👁 Xem chi tiết
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => admin.openUserDetail(u["_id"]),
                ),

                // ✏ Sửa
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => admin.openUserForm(u),
                ),

                // 🗑 Xóa — chỉ user thường
                if (u["role"] == "user")
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: "Xoá người dùng?",
                        message: "Bạn có chắc muốn xoá '${u["name"]}'?",
                        confirmColor: Colors.red,
                        confirmText: "Xoá",
                      );
                      if (!ok) return;

                      await admin.api.delete("/api/admin/users/${u['_id']}");
                      reload();
                      showSuccess(context, "Đã xoá người dùng");
                    },
                  ),
              ],
            );

            final full = [
              u["name"] ?? "",
              u["email"] ?? "",
              u["phone"] ?? "—",
              u["role"] ?? "",
              actions,
            ];

            return narrow ? [full[0], full[1], full[4]] : full;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: CommonTable(columns: columns, rows: rows),
          );
        },
      ),
    );
  }
}
