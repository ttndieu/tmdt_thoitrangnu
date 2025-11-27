// lib/modules/admin/products/components/variant_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final moneyFmt = NumberFormat("#,###", "vi_VN");

class VariantEditorDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? variant,
  }) {
    final sizeCtrl = TextEditingController(text: variant?['size'] ?? '');
    final colorCtrl = TextEditingController(text: variant?['color'] ?? '');
    final stockCtrl = TextEditingController(
      text: variant?['stock']?.toString() ?? '0',
    );
    final priceCtrl = TextEditingController(
      text: variant?['price']?.toString() ?? '0',
    );

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            variant == null ? 'Thêm biến thể' : 'Sửa biến thể',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SIZE
              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(labelText: 'Size'),
              ),
              const SizedBox(height: 8),

              // COLOR
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 8),

              // STOCK
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),

              // PRICE
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  value = value.replaceAll('.', '');

                  if (value.isEmpty) {
                    priceCtrl.text = '';
                    priceCtrl.selection = TextSelection.fromPosition(
                      const TextPosition(offset: 0),
                    );
                    return;
                  }

                  final number = int.tryParse(value);

                  if (number != null) {
                    final newText = moneyFmt.format(number);
                    priceCtrl.text = newText;
                    priceCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: newText.length),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = {
                  'size': sizeCtrl.text.trim(),
                  'color': colorCtrl.text.trim(),
                  'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                  'price':
                      int.tryParse(priceCtrl.text.replaceAll('.', '').trim()) ??
                      0,
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
