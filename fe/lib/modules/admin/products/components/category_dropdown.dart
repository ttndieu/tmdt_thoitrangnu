// lib/modules/admin/products/components/category_dropdown.dart
import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final List categories;
  final String? value;
  final void Function(String?) onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'Danh mục'),
      items: categories.map<DropdownMenuItem<String>>((cat) {
        if (cat is Map) {
          return DropdownMenuItem(value: cat['slug'], child: Text(cat['name'] ?? ''));
        } else if (cat is String) {
          return DropdownMenuItem(value: cat, child: Text(cat));
        }
        return const DropdownMenuItem(value: '', child: Text('Unknown'));
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Chọn danh mục' : null,
    );
  }
}
