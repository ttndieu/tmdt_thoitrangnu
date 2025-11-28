import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../admin_provider.dart';
import '../common/common_gap.dart';
import '../common/common_notify.dart';
import '../common/common_confirm.dart';
import 'orders_page.dart';
final moneyFmt = NumberFormat("#,###", "vi_VN");
class OrderDetailAdmin extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailAdmin({super.key, required this.order});

  @override
  State<OrderDetailAdmin> createState() => _OrderDetailAdminState();
}

class _OrderDetailAdminState extends State<OrderDetailAdmin> {
  late Map<String, dynamic> order;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
  }

  Future<void> updateStatus(String status) async {
    if (status == order["status"]) return;

    final ok = await showConfirmDialog(
      context,
      title: "Cập nhật trạng thái",
      message: "Bạn có muốn chuyển sang trạng thái '$status'?",
    );
    if (!ok) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);

    try {
      await admin.api.put(
        "/api/orders/${order["_id"]}/status",
        data: {"status": status},
      );

      setState(() => order["status"] = status);
      admin.selectedOrder = order;

      OrdersPageState.instance?.reload();
      showSuccess(context, "Đã cập nhật trạng thái");
    } catch (e) {
      showError(context, "Lỗi: $e");
    }
  }

  Widget _statusBtn(String s) {
    final active = order["status"] == s;
    return ElevatedButton(
      onPressed: active ? null : () => updateStatus(s),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.grey : Colors.blue,
        minimumSize: const Size(110, 40),
      ),
      child: Text(s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: admin.backToOrders,
              ),
              const Text(
                "Chi tiết đơn hàng",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          G.h20,

          _section("Mã đơn", Text(order["_id"])),

          _section(
            "Sản phẩm",
            Column(
              children: [
                for (final item in order["items"])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag, size: 20),
                        G.w12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["product"]["name"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "SL: ${item["quantity"]} | ${item["size"]}/${item["color"]}",
                              ),
                            ],
                          ),
                        ),
                        Text("${moneyFmt.format(item["price"] ?? 0)}đ"),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          _section(
            "Thanh toán",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Text("Tổng tiền: ${moneyFmt.format(order["totalAmount"] ?? 0)}đ"),
                Text("Phương thức: ${order["paymentMethod"]}"),
                Text("Trạng thái: ${order["status"]}"),
              ],
            ),
          ),

          _section(
            "Thông tin giao hàng",
            Text(
              "${order["shippingAddress"]["fullName"]}\n"
              "${order["shippingAddress"]["addressLine"]}, "
              "${order["shippingAddress"]["ward"]}, "
              "${order["shippingAddress"]["district"]}, "
              "${order["shippingAddress"]["city"]}\n"
              "SĐT: ${order["shippingAddress"]["phone"]}",
            ),
          ),

          _section(
            "Ngày đặt",
            Text(order["createdAt"].toString().substring(0, 19)),
          ),

          _section(
            "Cập nhật trạng thái",
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statusBtn("pending"),
                _statusBtn("confirmed"),
                _statusBtn("shipping"),
                _statusBtn("completed"),
                _statusBtn("cancelled"),
              ],
            ),
          ),
          _section(
            "Xuất hoá đơn",
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Xuất hoá đơn"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(150, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Provider.of<AdminProvider>(
                  context,
                  listen: false,
                ).exportInvoice(order);
              },
            ),
          ),

          G.h20,
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          G.h8,
          child,
        ],
      ),
    );
  }
}
