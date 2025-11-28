// lib/modules/admin/orders/orders_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../admin_provider.dart';
import '../common/common_table.dart';

final moneyFmt = NumberFormat("#,###", "vi_VN");
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  static OrdersPageState? instance;

  List<dynamic> orders = [];
  List<dynamic> original = [];

  // 🔥 NEW — lọc theo trạng thái
  String selectedStatus = "";

  // 🔥 NEW — danh sách trạng thái
  final List<String> statusList = [
    "pending",
    "confirmed",
    "shipping",
    "completed",
    "cancelled"
  ];

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
    final res = await admin.api.get("/api/orders/admin/all");

    original = List.from(res.data["orders"] ?? []);
    orders = List.from(original);

    // nếu có trạng thái đang chọn → áp dụng lọc
    if (selectedStatus.isNotEmpty) {
      _applyFilter();
    }

    setState(() {});
  }

  /// cho các page khác gọi reload
  void reload() => setState(() => loader = load());

  // ================= FILTER =================

  void filter(String q) {
    q = q.toLowerCase().trim();
    orders = original.where((o) {
      final id = o["_id"]?.toString() ?? "";
      final shortId = id.length >= 6 ? id.substring(id.length - 6) : id;
      final name = (o["user"]?["name"] ?? "").toString().toLowerCase();
      final status = (o["status"] ?? "").toLowerCase();
      return id.contains(q) || shortId.contains(q) || name.contains(q) || status.contains(q);
    }).toList();

    _applyFilter(); // vẫn áp dụng filter trạng thái
    setState(() {});
  }

  // 🔥 Lọc theo trạng thái
  void filterByStatus(String? s) {
    selectedStatus = s ?? "";
    _applyFilter();
    setState(() {});
  }

  // 🔥 áp dụng tất cả filter
  void _applyFilter() {
    orders = original.where((o) {
      final status = (o["status"] ?? "").toString();

      final matchStatus =
          selectedStatus.isEmpty ? true : status == selectedStatus;

      return matchStatus;
    }).toList();
  }

  String _shortId(String? id) {
    if (id == null) return "";
    final s = id.toString();
    return s.length >= 6 ? s.substring(s.length - 6) : s;
  }

  Widget _statusChip(String s) {
    Color c;
    switch (s) {
      case "pending":
        c = Colors.orange;
        break;
      case "confirmed":
        c = Colors.blue;
        break;
      case "shipping":
        c = Colors.purple;
        break;
      case "completed":
        c = Colors.green;
        break;
      case "cancelled":
        c = Colors.red;
        break;
      default:
        c = Colors.grey;
    }
    return Chip(
      label: Text(s),
      backgroundColor: c.withOpacity(0.12),
      labelStyle: TextStyle(color: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    final columns = isNarrow
        ? ["Mã đơn", "Người đặt", "Tổng", "Hành động"]
        : ["Mã đơn", "Người đặt", "Trạng thái", "Tổng", "Ngày đặt", "Hành động"];

    return Scaffold(
      body: FutureBuilder(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===================================================
                // 🔥 UI FILTER TRẠNG THÁI
                // ===================================================
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedStatus.isEmpty ? null : selectedStatus,
                      hint: const Text("Tất cả trạng thái"),
                      items: [
                        const DropdownMenuItem(
                          value: "",
                          child: Text("Tất cả trạng thái"),
                        ),
                        ...statusList.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            )),
                      ],
                      onChanged: filterByStatus,
                    ),

                    if (selectedStatus.isNotEmpty)
                      TextButton(
                        onPressed: () => filterByStatus(""),
                        child: const Text("Xóa lọc"),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===================================================
                // TABLE
                // ===================================================
                Expanded(
                  child: orders.isEmpty
                      ? const Center(child: Text("Không có đơn hàng"))
                      : CommonTable(columns: columns, rows: orders.map<List<dynamic>>((o) {
                          final id = o["_id"]?.toString() ?? "";
                          final short = _shortId(id);
                          final userName = o["user"]?["name"] ?? "—";
                          final status = o["status"]?.toString() ?? "";
                          final total = o["totalAmount"]?? "0";
                          final date = (o["createdAt"]?.toString() ?? "").substring(0, 10);

                          final actions = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  Provider.of<AdminProvider>(context, listen: false)
                                      .openOrderDetail(o);
                                },
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return [short, userName, "${moneyFmt.format(total)}đ", actions];
                          }

                          return [
                            short,
                            userName,
                            _statusChip(status),
                            "${moneyFmt.format(total)}đ",
                            date,
                            actions,
                          ];
                        }).toList()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
