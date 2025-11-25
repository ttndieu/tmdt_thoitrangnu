// lib/modules/admin/users/user_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../common/common_card.dart';
import '../common/common_section.dart';
import '../common/common_gap.dart';

class UserFormPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _role = "user";

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _name.text = widget.user!["name"] ?? "";
      _phone.text = widget.user!["phone"] ?? "";
      _role = widget.user!["role"] ?? "user";
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => admin.backToUsers(),
            ),
            const Text("Cập nhật người dùng",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        G.h16,

        Expanded(
          child: ListView(
            children: [
              CommonCard(
                child: CommonSection(
                  title: "Thông tin người dùng",
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration:
                            const InputDecoration(labelText: "Tên người dùng"),
                      ),
                      G.h12,
                      TextField(
                        controller: _phone,
                        decoration:
                            const InputDecoration(labelText: "Số điện thoại"),
                      ),
                      G.h12,
                      DropdownButtonFormField(
                        value: _role,
                        decoration: const InputDecoration(labelText: "Vai trò"),
                        items: const [
                          DropdownMenuItem(
                              value: "user", child: Text("User")),
                          DropdownMenuItem(
                              value: "admin", child: Text("Admin")),
                        ],
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                    ],
                  ),
                ),
              ),
              G.h20,
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      "name": _name.text.trim(),
                      "phone": _phone.text.trim(),
                      "role": _role,
                    };

                    if (widget.user == null) {
                      await admin.api.post("/api/admin/users", data: payload);
                    } else {
                      await admin.api.put(
                        "/api/admin/users/${widget.user!['_id']}",
                        data: payload,
                      );
                    }

                    admin.backToUsers();
                  },
                  child: Text(widget.user == null ? "Tạo mới" : "Cập nhật"),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
