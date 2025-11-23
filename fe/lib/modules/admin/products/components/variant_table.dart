// lib/modules/admin/products/components/variant_table.dart
import 'package:flutter/material.dart';

class VariantTable extends StatelessWidget {
  final List<Map<String, dynamic>> variants;
  final VoidCallback onAdd;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  const VariantTable({
    super.key,
    required this.variants,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Variants", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text("Thêm")),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Color")),
              DataColumn(label: Text("Stock")),
              DataColumn(label: Text("Price")),
              DataColumn(label: Text("Actions")),
            ],
            rows: List<DataRow>.generate(variants.length, (i) {
              final v = variants[i];
              return DataRow(cells: [
                DataCell(Text(v['color']?.toString() ?? '')),
                DataCell(Text(v['stock']?.toString() ?? '0')),
                DataCell(Text(v['price']?.toString() ?? '0')),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(i)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onDelete(i)),
                  ],
                )),
              ]);
            }),
          ),
        )
      ],
    );
  }
}
