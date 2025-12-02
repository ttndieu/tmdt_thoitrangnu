import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../common/common_confirm.dart';
import '../common/common_notify.dart';

Future<void> showVoucherFormDialog(
  BuildContext context, {
  Map<String, dynamic>? voucher,
  required Function(Map<String, dynamic>) onSaved,
}) async {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherSheet(
        voucher: voucher,
        onSaved: onSaved,
      ),
    );
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VoucherDialog(
      voucher: voucher,
      onSaved: onSaved,
    ),
  );
}

// DESKTOP / WEB — DIALOG
class _VoucherDialog extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  final Function(Map<String, dynamic>) onSaved;

  const _VoucherDialog({required this.voucher, required this.onSaved});

  @override
  State<_VoucherDialog> createState() => _VoucherDialogState();
}

class _VoucherDialogState extends State<_VoucherDialog> {
  final _form = GlobalKey<FormState>();
  final code = TextEditingController();
  final discount = TextEditingController();
  final maxDiscount = TextEditingController();
  final minOrder = TextEditingController();
  final quantity = TextEditingController();
  DateTime? expires;
  bool active = true;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    if (v != null) {
      code.text = v["code"] ?? "";
      discount.text = "${v["discountPercent"]}";
      maxDiscount.text = "${v["maxDiscount"]}";
      minOrder.text = "${v["minOrderValue"]}";
      quantity.text = "${v["quantity"]}";
      expires = DateTime.tryParse(v["expiredAt"]);
      active = v["active"] ?? true;
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (expires == null) return showError(context, "Chọn ngày hết hạn");

    final ok = await showConfirmDialog(
      context,
      title: widget.voucher == null ? "Tạo voucher?" : "Cập nhật voucher?",
      message: "Bạn có chắc không?",
    );
    if (!ok) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);

    final data = {
      "code": code.text.trim().toUpperCase(),
      "discountPercent": int.parse(discount.text),
      "maxDiscount": int.parse(maxDiscount.text),
      "minOrderValue": int.parse(minOrder.text),
      "quantity": int.parse(quantity.text),
      "expiredAt": expires!.toIso8601String(),
      "active": active,
    };

    final api = admin.api;
    final res = widget.voucher == null
        ? await api.post("/api/voucher", data: data)
        : await api.put("/api/voucher/${widget.voucher!['_id']}", data: data);

    widget.onSaved(res.data["voucher"]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  widget.voucher == null ? "Tạo voucher" : "Cập nhật",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _field(code, "Mã voucher *"),
                _field(discount, "% giảm *", number: true),
                _field(maxDiscount, "Giảm tối đa (VNĐ) *", number: true),
                _field(minOrder, "Đơn tối thiểu (VNĐ) *", number: true),
                _field(quantity, "Số lượng *", number: true),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    expires == null
                        ? "Chọn ngày hết hạn *"
                        : "Hết hạn: ${expires!.toString().split(" ")[0]}",
                    style: TextStyle(color: expires == null ? Colors.red : null),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: expires ?? DateTime.now(),
                    );
                    if (d != null) setState(() => expires = d);
                  },
                  trailing: const Icon(Icons.calendar_month),
                ),

                SwitchListTile(
                  title: const Text("Kích hoạt"),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                    ElevatedButton(onPressed: _submit, child: const Text("Lưu")),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v == null || v.isEmpty ? "Không để trống" : null,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }
}


// MOBILE — BOTTOM SHEET

class _VoucherSheet extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  final Function(Map<String, dynamic>) onSaved;

  const _VoucherSheet({required this.voucher, required this.onSaved});

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final _form = GlobalKey<FormState>();
  final code = TextEditingController();
  final discount = TextEditingController();
  final maxDiscount = TextEditingController();
  final minOrder = TextEditingController();
  final quantity = TextEditingController();
  DateTime? expires;
  bool active = true;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    if (v != null) {
      code.text = v["code"] ?? "";
      discount.text = "${v["discountPercent"]}";
      maxDiscount.text = "${v["maxDiscount"]}";
      minOrder.text = "${v["minOrderValue"]}";
      quantity.text = "${v["quantity"]}";
      expires = DateTime.tryParse(v["expiredAt"]);
      active = v["active"] ?? true;
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (expires == null) return showError(context, "Chọn ngày hết hạn");

    final ok = await showConfirmDialog(context,
        title: widget.voucher == null ? "Tạo voucher?" : "Cập nhật?",
        message: "Bạn có chắc không?");
    if (!ok) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);

    final data = {
      "code": code.text.trim().toUpperCase(),
      "discountPercent": int.parse(discount.text),
      "maxDiscount": int.parse(maxDiscount.text),
      "minOrderValue": int.parse(minOrder.text),
      "quantity": int.parse(quantity.text),
      "expiredAt": expires!.toIso8601String(),
      "active": active,
    };

    final res = widget.voucher == null
        ? await admin.api.post("/api/voucher", data: data)
        : await admin.api.put("/api/voucher/${widget.voucher!['_id']}", data: data);

    widget.onSaved(res.data["voucher"]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: Form(
            key: _form,
            child: Column(
              children: [
                Text(
                  widget.voucher == null ? "Tạo voucher" : "Cập nhật voucher",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _field(code, "Mã voucher *"),
                _field(discount, "% giảm *", number: true),
                _field(maxDiscount, "Giảm tối đa (VNĐ) *", number: true),
                _field(minOrder, "Đơn tối thiểu (VNĐ) *", number: true),
                _field(quantity, "Số lượng *", number: true),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    expires == null
                        ? "Chọn ngày hết hạn *"
                        : "Hết hạn: ${expires!.toString().split(" ")[0]}",
                    style: TextStyle(color: expires == null ? Colors.red : null),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: expires ?? DateTime.now(),
                    );
                    if (d != null) setState(() => expires = d);
                  },
                ),

                SwitchListTile(
                  title: const Text("Kích hoạt"),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                    ElevatedButton(onPressed: _submit, child: const Text("Lưu")),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v == null || v.isEmpty ? "Không để trống" : null,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }
}
