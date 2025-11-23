// lib/modules/admin/orders/orders_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  static OrdersPageState? instance;

  List<dynamic> orders = [];
  List<dynamic> originalOrders = [];
  late Future<void> loader;

  @override
  void initState() {
    super.initState();
    instance = this;
    loader = loadOrders();
  }

  // ----------------------------------------
  // LOAD ORDERS
  // ----------------------------------------
  Future<void> loadOrders() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/orders/admin/all");

    setState(() {
      originalOrders = List.from(res.data["orders"]);
      orders = List.from(originalOrders);
    });
  }

  // ----------------------------------------
  // SEARCH FILTER
  // ----------------------------------------
  void filter(String query) {
    setState(() {
      if (query.isEmpty) {
        orders = List.from(originalOrders);
      } else {
        final lower = query.toLowerCase();
        orders = originalOrders.where((o) {
          final id = o["_id"]?.toString().toLowerCase() ?? "";
          final shortId =
              id.isNotEmpty ? id.substring(id.length - 6).toLowerCase() : "";

          return id.contains(lower) || shortId.contains(lower);
        }).toList();
      }
    });
  }

  // ----------------------------------------
  // UPDATE ORDER STATUS
  // ----------------------------------------
  Future<void> updateStatus(String orderId, String status) async {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await admin.api.put("/api/orders/$orderId/status", data: {"status": status});

      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cập nhật trạng thái thành công!")),
      );

      await loadOrders();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // ----------------------------------------
  // SHOW ORDER DETAIL
  // ----------------------------------------
  void openDetail(Map<String, dynamic> order) {
    final String id = order["_id"];
    final String shortId = id.substring(id.length - 6);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller,
                children: [
                  Text("Đơn hàng #$shortId",
                      style:
                          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Text("Trạng thái: ${order['status']}"),
                  const SizedBox(height: 12),

                  const Text("Sản phẩm:",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  ...order["items"].map<Widget>((item) {
                    return ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(item["product"]?["name"] ?? "Sản phẩm"),
                      subtitle: Text(
                          "SL: ${item["quantity"]} | ${item["size"]}/${item["color"]}"),
                      trailing: Text("${item["price"]}đ"),
                    );
                  }).toList(),

                  const Divider(height: 24),

                  Text("Tổng tiền: ${order['totalAmount']}đ",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  const Text("Cập nhật trạng thái:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      _statusBtn(id, "pending"),
                      _statusBtn(id, "confirmed"),
                      _statusBtn(id, "shipping"),
                      _statusBtn(id, "completed"),
                      _statusBtn(id, "cancelled"),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBtn(String id, String status) {
    return ElevatedButton(
      onPressed: () => updateStatus(id, status),
      child: Text(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đơn hàng")),
      body: FutureBuilder(
        future: loader,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orders.isEmpty) {
            return const Center(child: Text("Không có đơn hàng"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final o = orders[i];
              final id = o["_id"];
              final shortId = id.substring(id.length - 6);

              return ListTile(
                title: Text("Đơn hàng #$shortId"),
                subtitle: Text("Trạng thái: ${o['status']}"),
                onTap: () => openDetail(o),
              );
            },
          );
        },
      ),
    );
  }
}
