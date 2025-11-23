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
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VoucherFormDialog(
      voucher: voucher,
      onSaved: onSaved,
    ),
  );
}

class _VoucherFormDialog extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  final Function(Map<String, dynamic>) onSaved;

  const _VoucherFormDialog({
    required this.voucher,
    required this.onSaved,
  });

  @override
  State<_VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<_VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();

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
    if (widget.voucher != null) {
      final v = widget.voucher!;
      code.text = v["code"] ?? "";
      discount.text = v["discountPercent"].toString();
      maxDiscount.text = v["maxDiscount"].toString();
      minOrder.text = v["minOrderValue"].toString();
      quantity.text = v["quantity"].toString();
      expires = DateTime.tryParse(v["expiredAt"]);
      active = v["active"] ?? true;
    }
  }

  // ============================= VALIDATE FULL =============================
  String? _validateRequired(String? v) =>
      (v == null || v.isEmpty) ? "Không được để trống" : null;

  // ============================= SUBMIT =============================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra ngày hết hạn
    if (expires == null) {
      showError(context, "Vui lòng chọn ngày hết hạn");
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: widget.voucher == null ? "Tạo voucher?" : "Cập nhật voucher?",
      message: "Bạn có chắc muốn lưu thay đổi không?",
    );

    if (!ok) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);

    final body = {
      "code": code.text.trim().toUpperCase(),
      "discountPercent": int.parse(discount.text),
      "maxDiscount": int.parse(maxDiscount.text),
      "minOrderValue": int.parse(minOrder.text),
      "quantity": int.parse(quantity.text),
      "expiredAt": expires!.toIso8601String(),
      "active": active,
    };

    Map<String, dynamic> result;

    if (widget.voucher == null) {
      final res = await admin.api.post("/api/voucher", data: body);
      result = Map<String, dynamic>.from(res.data["voucher"]);
    } else {
      final res = await admin.api.put(
        "/api/voucher/${widget.voucher!['_id']}",
        data: body,
      );
      result = Map<String, dynamic>.from(res.data["voucher"]);
    }

    widget.onSaved(result);
    Navigator.pop(context);
  }

  // ============================= UI =============================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.voucher == null
                          ? Icons.confirmation_num
                          : Icons.edit,
                      size: 28,
                      color: theme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.voucher == null
                          ? "Tạo voucher mới"
                          : "Cập nhật voucher",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _input(code, "Mã voucher", required: true),
                _space(),
                _input(discount, "% giảm", number: true, required: true),
                _space(),
                _input(maxDiscount, "Giảm tối đa (VNĐ)", number: true, required: true),
                _space(),
                _input(minOrder, "Đơn tối thiểu (VNĐ)", number: true, required: true),
                _space(),
                _input(quantity, "Số lượng", number: true, required: true),
                _space(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    expires == null
                        ? "Chọn ngày hết hạn *"
                        : "Hết hạn: ${expires.toString().split(" ")[0]}",
                    style: TextStyle(
                      color: expires == null ? Colors.red : null,
                      fontWeight: expires == null ? FontWeight.bold : null,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_month, color: theme.primary),
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
                  activeColor: theme.primary,
                  onChanged: (v) => setState(() => active = v),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: submit,
                      child: Text(widget.voucher == null ? "Tạo" : "Cập nhật"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    bool number = false,
    bool required = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required ? _validateRequired : null,
    );
  }

  Widget _space() => const SizedBox(height: 14);
}
