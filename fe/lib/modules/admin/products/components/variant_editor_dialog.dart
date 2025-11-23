// lib/modules/admin/products/components/variant_editor_dialog.dart
import 'package:flutter/material.dart';

class VariantEditorDialog {
  static Future<Map<String, dynamic>?> show(BuildContext context, {Map<String, dynamic>? variant}) {
    final colorCtrl = TextEditingController(text: variant?['color'] ?? '');
    final stockCtrl = TextEditingController(text: variant?['stock']?.toString() ?? '0');
    final priceCtrl = TextEditingController(text: variant?['price']?.toString() ?? '0');

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(variant == null ? 'Thêm variant' : 'Sửa variant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Color')),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final result = {
                  'color': colorCtrl.text.trim(),
                  'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                  'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                };
                Navigator.pop(ctx, result);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
