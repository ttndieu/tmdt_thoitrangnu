import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../admin_home_page.dart';
import '../admin_menu.dart';
import '../common/common_confirm.dart';   // ⬅ thêm dòng này để dùng dialog

const Color kPink = Color.fromARGB(255, 197, 151, 185);

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Container(
      width: 240,
      decoration: const BoxDecoration(color: kPink),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset("assets/logo.png", width: 90),
          const SizedBox(height: 6),
          const Text(
            "ADMIN",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ================= MENU =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: adminMenuItems.map((item) {
                final selected = item["route"] == admin.currentRoute;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.35) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Icon(item["icon"], color: Colors.white),
                    title: Text(item["label"], style: const TextStyle(color: Colors.white)),
                    onTap: () => admin.changeRoute(item["route"]),
                  ),
                );
              }).toList(),
            ),
          ),

          // ================= LOGOUT =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: "Đăng xuất?",
                  message: "Bạn có chắc chắn muốn đăng xuất không?",
                  confirmColor: Colors.red,
                  confirmText: "Đăng xuất",
                  cancelText: "Hủy",
                );

                if (ok) admin.logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Đăng xuất"),
            ),
          ),
        ],
      ),
    );
  }
}
