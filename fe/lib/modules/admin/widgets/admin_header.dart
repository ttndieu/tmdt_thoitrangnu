import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class AdminHeader extends StatelessWidget {
  final TextEditingController controller;
  final bool isDesktop;
  final Function(String) onSearch;

  const AdminHeader({
    super.key,
    required this.controller,
    required this.isDesktop,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Tìm kiếm...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onSearch,
            ),
          ),
        ],
      ),
    );
  }
}
