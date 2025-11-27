// lib/modules/admin/admin_provider.dart

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../core/network/api_client.dart';
import '../../modules/auth/providers/auth_provider.dart';
import 'admin_routes.dart';

class AdminProvider with ChangeNotifier {
  final AuthProvider auth;
  final ApiClient api;

  AdminProvider(this.auth, this.api);

  String _currentRoute = AdminRoutes.dashboard;
  String get currentRoute => _currentRoute;

  bool get isAdmin => auth.user?.role == "admin";
  String? get token => auth.user?.token;

  // SIDEBAR
  bool isSidebarCollapsed = false;
  void toggleSidebar() {
    isSidebarCollapsed = !isSidebarCollapsed;
    notifyListeners();
  }

  // ========================= PRODUCTS =========================
  String? selectedProductId;
  String? editingProductId;
  Map<String, dynamic>? editingProductData;

  void openProductDetail(String id) {
    selectedProductId = id;
    _currentRoute = AdminRoutes.productDetail;
    notifyListeners();
  }

  void openProductForm([Map<String, dynamic>? product]) {
    editingProductData = product;
    editingProductId = product?['_id'];
    _currentRoute = AdminRoutes.productForm;
    notifyListeners();
  }

  void backToProducts() {
    selectedProductId = null;
    editingProductId = null;
    editingProductData = null;
    _currentRoute = AdminRoutes.products;
    notifyListeners();
  }

  // ========================= USERS =========================
  String? selectedUserId;
  Map<String, dynamic>? editingUser;

  void openUserDetail(String id) {
    selectedUserId = id;
    _currentRoute = AdminRoutes.userDetail;
    notifyListeners();
  }

  void openUserForm([Map<String, dynamic>? user]) {
    editingUser = user;
    _currentRoute = AdminRoutes.userForm;
    notifyListeners();
  }

  void backToUsers() {
    selectedUserId = null;
    editingUser = null;
    _currentRoute = AdminRoutes.users;
    notifyListeners();
  }

  // ========================= ORDERS =========================
  Map<String, dynamic>? selectedOrder;

  void openOrderDetail(Map<String, dynamic> order) {
    selectedOrder = order;
    _currentRoute = AdminRoutes.orderDetail;
    notifyListeners();
  }

  /// Load lại đơn hàng sau khi cập nhật trạng thái
  Future<void> refreshOrder(String id) async {
    try {
      final res = await api.get("/api/orders/$id/admin");
      selectedOrder = res.data["order"];
      notifyListeners();
    } catch (_) {}
  }

  void backToOrders() {
    selectedOrder = null;
    _currentRoute = AdminRoutes.orders;
    notifyListeners();
  }

// =========================
// XUẤT HOÁ ĐƠN
// =========================
void exportInvoice(Map<String, dynamic> order) async {
  final pdf = pw.Document();

  final items = order["items"] as List<dynamic>;
  final shipping = order["shippingAddress"];

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
      ),
      build: (context) => [
        // ---------------- HEADER ----------------
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("HÓA ĐƠN BÁN HÀNG",
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text("Mã đơn: ${order["_id"]}"),
                pw.Text("Ngày: ${order["createdAt"].toString().substring(0, 10)}"),
              ],
            ),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: order["_id"],
              width: 80,
              height: 80,
            ),
          ],
        ),

        pw.SizedBox(height: 20),

        // ---------------- CUSTOMER INFO ----------------
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(6),
              color: PdfColors.grey100),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Thông tin khách hàng",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text("Tên: ${shipping["fullName"]}"),
              pw.Text("SĐT: ${shipping["phone"]}"),
              pw.Text(
                "Địa chỉ: ${shipping["addressLine"]}, ${shipping["ward"]}, "
                "${shipping["district"]}, ${shipping["city"]}",
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // ---------------- PRODUCT TABLE ----------------
        pw.Table.fromTextArray(
          headers: ["Sản phẩm", "SL", "Size/Màu", "Giá", "Tổng"],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey900),
          cellAlignment: pw.Alignment.centerLeft,
          data: items.map((e) {
            final total = e["price"] * e["quantity"];
            return [
              e["product"]["name"],
              e["quantity"].toString(),
              "${e["size"]}/${e["color"]}",
              "${e["price"]}đ",
              "$total đ",
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 20),

        // ---------------- TOTAL ----------------
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            width: 280,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _totalRow("Tổng tiền hàng:",
                    "${order["originalAmount"] ?? order["totalAmount"]} đ"),
                _totalRow("Giảm giá:", "${order["discount"] ?? 0} đ"),
                pw.Divider(),
                _totalRow(
                  "Thành tiền:",
                  "${order["totalAmount"]} đ",
                  bold: true,
                  font: 16,
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 40),

        // ---------------- FOOTER ----------------
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text("Cảm ơn bạn đã mua hàng!",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Nếu cần hỗ trợ, vui lòng liên hệ shop."),
            ],
          ),
        ),
      ],
    ),
  );

  // Xuất PDF
  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}

pw.Widget _totalRow(String label, String value,
    {bool bold = false, double font = 14}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
              fontSize: font,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            )),
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: font,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            )),
      ],
    ),
  );
}


  // ========================= ROUTE HANDLING =========================
  void changeRoute(String route) {
    _currentRoute = route;

    if (route != AdminRoutes.productDetail) selectedProductId = null;
    if (route != AdminRoutes.productForm) {
      editingProductId = null;
      editingProductData = null;
    }

    if (route != AdminRoutes.userDetail) selectedUserId = null;
    if (route != AdminRoutes.userForm) editingUser = null;

    if (route != AdminRoutes.orderDetail) selectedOrder = null;

    notifyListeners();
  }


  // ========================= LOGOUT =========================
  Future<void> logout(BuildContext context) async {
    await auth.logout();
    _currentRoute = AdminRoutes.dashboard;

    selectedProductId = null;
    editingProductId = null;
    editingProductData = null;

    selectedUserId = null;
    editingUser = null;

    selectedOrder = null;

    notifyListeners();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }
}