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
  List<dynamic> original = [];
  late Future<void> loader;

  @override
  void initState() {
    super.initState();
    instance = this;
    loader = loadOrders();
  }

  Future<void> loadOrders() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/orders");

    setState(() {
      original = List.from(res.data["orders"]);
      orders = List.from(original);
    });
  }

  void filter(String query) {
    setState(() {
      if (query.isEmpty) {
        orders = List.from(original);
      } else {
        final q = query.toLowerCase();
        orders = original.where((o) {
          final id = (o["_id"] ?? "").toString().toLowerCase();
          final shortId = id.length >= 6 ? id.substring(id.length - 6) : id;
          final status = (o["status"] ?? "").toString().toLowerCase();

          return id.contains(q) ||
                 shortId.contains(q) ||
                 status.contains(q);
        }).toList();
      }
    });
  }

  void reload() => setState(() => loader = loadOrders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đơn hàng")),
      body: FutureBuilder(
        future: loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orders.isEmpty) {
            return const Center(child: Text("Chưa có đơn hàng nào"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = orders[i];
              final id = o["_id"] ?? "";
              final shortId = id.length >= 6 ? id.substring(id.length - 6) : id;

              return ListTile(
                title: Text("Đơn hàng #$shortId"),
                subtitle: Text("Trạng thái: ${o["status"]}"),
              );
            },
          );
        },
      ),
    );
  }
}
