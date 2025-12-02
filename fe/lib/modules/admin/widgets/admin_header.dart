import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../common/common_confirm.dart';


class AdminHeader extends StatelessWidget {
  final TextEditingController controller;
  final bool isDesktop;
  final Function(String) onSearch;

  const AdminHeader({
    super.key,
    required this.controller,
    required this.isDesktop,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(top: 10), // ⭐ thụt xuống
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ô tìm kiếm
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Color(0xFFF5F1F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onSearch,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Tìm kiếm...",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logout icon
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
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
          ),
        ],
      ),
    );
  }
}
