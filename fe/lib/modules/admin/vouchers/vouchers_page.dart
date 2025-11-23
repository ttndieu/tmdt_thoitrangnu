import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

// form popup
import 'voucher_form_dialog.dart';

// bảng dùng chung
import '../common/common_table.dart';

// confirm dialog dùng chung
import '../common/common_confirm.dart';
import '../common/common_notify.dart';

class VouchersPage extends StatefulWidget {
  const VouchersPage({super.key});

  @override
  State<VouchersPage> createState() => VouchersPageState();
}

class VouchersPageState extends State<VouchersPage> {
  static VouchersPageState? instance;

  List vouchers = [];
  List original = [];
  late Future loader;

  @override
  void initState() {
    super.initState();
    instance = this;
    loader = load();
  }

  // =============================== LOAD DATA ===============================
  Future<void> load() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/voucher");

    setState(() {
      original = res.data["vouchers"];
      vouchers = List.from(original);
    });
  }

  void reload() => setState(() => loader = load());

  // =============================== SEARCH ===============================
  void filter(String q) {
    q = q.toLowerCase().trim();

    setState(() {
      vouchers = q.isEmpty
          ? List.from(original)
          : original.where((v) {
              final code = (v["code"] ?? "").toString().toLowerCase();
              return code.contains(q);
            }).toList();
    });
  }

  // =============================== UI ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showVoucherFormDialog(
            context,
            onSaved: (newVoucher) {
              setState(() {
                vouchers.add(newVoucher);
                original.add(newVoucher);
              });
              showSuccess(context, "Đã tạo voucher");
            },
          );
        },
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder(
        future: loader,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vouchers.isEmpty) {
            return const Center(child: Text("Không có voucher"));
          }

          // =============================== CHUẨN HÓA DATA ROWS ===============================
          final rows = vouchers.map<List<dynamic>>((v) {
            return [
              v["code"],
              "${v["discountPercent"]}%",
              "${v["maxDiscount"]} đ",
              "${v["minOrderValue"]} đ",
              "${v["quantity"]}",
              v["expiredAt"]?.toString().split("T")[0] ?? "",
              v["active"] == true
                  ? const Text("Đang kích hoạt", style: TextStyle(color: Colors.green))
                  : const Text("Tắt", style: TextStyle(color: Colors.red)),
              
              // ---- Hành động ----
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      await showVoucherFormDialog(
                        context,
                        voucher: v,
                        onSaved: (updated) {
                          setState(() {
                            final idx = vouchers.indexWhere((e) => e["_id"] == updated["_id"]);
                            if (idx != -1) {
                              vouchers[idx] = updated;
                              original[idx] = updated;
                            }
                          });
                          showSuccess(context, "Đã cập nhật voucher");
                        },
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: "Xóa voucher?",
                        message: "Bạn có chắc muốn xóa mã ${v["code"]} không?",
                        confirmColor: Colors.red,
                        confirmText: "Xóa",
                      );

                      if (!ok) return;

                      final admin = Provider.of<AdminProvider>(context, listen: false);
                      await admin.api.delete("/api/voucher/${v["_id"]}");

                      setState(() {
                        vouchers.remove(v);
                        original.remove(v);
                      });

                      showSuccess(context, "Đã xóa voucher");
                    },
                  ),
                ],
              ),
            ];
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: CommonTable(
              columns: const [
                "Mã",
                "% giảm",
                "Giảm tối đa",
                "Đơn tối thiểu",
                "SL còn",
                "Hết hạn",
                "Trạng thái",
                "Hành động",
              ],
              rows: rows,
            ),
          );
        },
      ),
    );
  }
}
