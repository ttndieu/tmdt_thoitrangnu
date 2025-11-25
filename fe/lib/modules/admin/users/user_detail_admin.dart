// lib/modules/admin/users/user_detail_admin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../common/common_card.dart';
import '../common/common_section.dart';
import '../common/common_gap.dart';

class UserDetailAdmin extends StatelessWidget {
  final String userId;
  const UserDetailAdmin({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return FutureBuilder(
      future: admin.api.get("/api/admin/users/$userId"),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) {
          return const Center(child: Text("Không tìm thấy người dùng"));
        }

        final user = snap.data!.data["user"];
        final avatar = user["avatar"] ??
            "https://ui-avatars.com/api/?name=${user['name']}";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => admin.backToUsers(),
                ),
                const SizedBox(width: 8),
                const Text("Chi tiết người dùng",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            G.h16,

            Expanded(
              child: ListView(
                children: [
                  CommonCard(
                    child: CommonSection(
                      title: "Thông tin",
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(avatar),
                          ),
                          G.w16,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tên: ${user['name']}"),
                                Text("Email: ${user['email']}"),
                                Text("SĐT: ${user['phone'] ?? '—'}"),
                                Text("Vai trò: ${user['role']}"),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  // ĐỊA CHỈ
                  if ((user["addresses"] as List).isNotEmpty)
                    CommonCard(
                      child: CommonSection(
                        title: "Địa chỉ",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...(user["addresses"] as List).map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                    "• ${a['fullName']} – ${a['phone']}\n  ${a['addressLine']}, ${a['ward']}, ${a['district']}, ${a['city']}"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
