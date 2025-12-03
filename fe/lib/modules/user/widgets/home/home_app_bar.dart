// lib/modules/user/widgets/home/home_app_bar.dart

import 'package:flutter/material.dart';
import '../../constants/app_color.dart';
import '../../constants/app_text_styles.dart';

class HomeAppBar extends StatelessWidget {
  final String userName;
  final String? avatarUrl; 
  final int cartCount;
  final int notificationCount;
  final VoidCallback onCartTap;
  final VoidCallback onNotificationTap;

  const HomeAppBar({
    Key? key,
    required this.userName,
    this.avatarUrl, 
    this.cartCount = 0,
    this.notificationCount = 0,
    required this.onCartTap,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar + Greeting
          Expanded(
            child: Row(
              children: [
                // Avatar with Image
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatar(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Greeting Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xin chào 👋',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: AppTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cart Button
          _IconButton(
            icon: Icons.shopping_cart_outlined,
            badge: cartCount,
            onTap: onCartTap,
            tooltip: 'Giỏ hàng',
          ),
          const SizedBox(width: 8),

          // Notification Button
          _IconButton(
            icon: Icons.notifications_outlined,
            badge: notificationCount,
            onTap: onNotificationTap,
            tooltip: 'Thông báo',
          ),
        ],
      ),
    );
  }

  // THÊM FUNCTION HIỂN THỊ AVATAR
  Widget _buildAvatar() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return const Icon(
      Icons.person,
      color: Colors.white,
      size: 24,
    );
  }
}

// GIỮ NGUYÊN _IconButton CLASS
class _IconButton extends StatefulWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconButton({
    required this.icon,
    required this.badge,
    required this.onTap,
    this.tooltip,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.badge > 0 
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.icon,
                    color: widget.badge > 0 
                      ? AppColors.primary 
                      : AppColors.textPrimary,
                    size: 24,
                  ),
                ),
                
                if (widget.badge > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.badge,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.badge.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          widget.badge > 99 ? '99+' : '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}