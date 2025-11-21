import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onCartTap;
  final VoidCallback? onMessageTap;
  final int cartItemCount;
  final bool hasNewMessage;
  final Function(String)? onSearchChanged;

  const CustomAppBar({
    Key? key,
    this.onCartTap,
    this.onMessageTap,
    this.cartItemCount = 0,
    this.hasNewMessage = false,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white.withOpacity(0.95),
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildSearchBar(context),
      ),
      actions: [
        IconButton(
          onPressed: onCartTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: AppColors.darkText, size: 24),
              if (cartItemCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      cartItemCount > 99 ? '99+' : '$cartItemCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: onMessageTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.message_outlined, color: AppColors.darkText, size: 24),
              if (hasNewMessage)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    Timer? _debounce;

    void _onChanged(String value) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (onSearchChanged != null) onSearchChanged!(value);
      });
    }

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm váy đầm, áo kiểu…',
        prefixIcon: const Icon(Icons.search, color: AppColors.darkText, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
