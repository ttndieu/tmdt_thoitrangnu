import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class VoucherFormPage extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  const VoucherFormPage({super.key, this.voucher});

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);

    final body = {
      "code": code.text.trim(),
      "discountPercent": int.parse(discount.text),
      "maxDiscount": int.parse(maxDiscount.text),
      "minOrderValue": int.parse(minOrder.text),
      "quantity": int.parse(quantity.text),
      "expiredAt": expires?.toIso8601String(),
      "active": active
    };

    if (widget.voucher == null) {
      await admin.api.post("/api/voucher", data: body);
    } else {
      await admin.api.put("/api/voucher/${widget.voucher!['_id']}", data: body);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.voucher == null
              ? "Tạo voucher"
              : "Cập nhật voucher")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: code,
                decoration: const InputDecoration(labelText: "Mã voucher"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Không được trống" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: discount,
                decoration: const InputDecoration(labelText: "% giảm"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: maxDiscount,
                decoration:
                    const InputDecoration(labelText: "Giảm tối đa (VNĐ)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: minOrder,
                decoration:
                    const InputDecoration(labelText: "Đơn tối thiểu (VNĐ)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: quantity,
                decoration: const InputDecoration(labelText: "Số lượng"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(expires == null
                    ? "Chọn ngày hết hạn"
                    : "Hết hạn: ${expires.toString().split(' ')[0]}"),
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
                value: active,
                title: const Text("Kích hoạt"),
                onChanged: (v) => setState(() => active = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submit,
                child: Text(widget.voucher == null ? "Tạo" : "Cập nhật"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
