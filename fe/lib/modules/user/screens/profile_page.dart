// lib/modules/user/screens/profile_page.dart

import 'package:fe/modules/user/constants/app_color.dart';
import 'package:fe/modules/user/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;

            return CustomScrollView(
              slivers: [
                // Header with User Info
                SliverToBoxAdapter(
                  child: _buildHeader(context, user, authProvider),
                ),

                // Stats Section
                SliverToBoxAdapter(
                  child: _buildStatsSection(context),
                ),

                // Menu Items
                SliverToBoxAdapter(
                  child: _buildMenuSection(context, authProvider),
                ),

                // Logout Button
                SliverToBoxAdapter(
                  child: _buildLogoutButton(context, authProvider),
                ),

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  image: user?.avatar != null
                      ? DecorationImage(
                          image: NetworkImage(user.avatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: user?.avatar == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to edit profile
                    print('Edit avatar');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            user?.name ?? 'Khách',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // User Email
          Text(
            user?.email ?? 'guest@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),

          // Edit Profile Button
          GestureDetector(
            onTap: () {
              // TODO: Navigate to edit profile
              print('Edit profile');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Chỉnh sửa hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.shopping_bag_outlined,
              count: '12',
              label: 'Đơn hàng',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_outline,
              count: '24',
              label: 'Yêu thích',
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star_outline,
              count: '150',
              label: 'Điểm',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Account
          const Text('Tài khoản', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Đơn hàng của tôi',
                  subtitle: 'Xem lịch sử đơn hàng',
                  onTap: () {
                    // TODO: Navigate to orders
                    print('Orders');
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Địa chỉ',
                  subtitle: 'Quản lý địa chỉ giao hàng',
                  badge: authProvider.user?.addresses.length.toString(),
                  onTap: () {
                    // TODO: Navigate to addresses
                    print('Addresses');
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.favorite_border,
                  title: 'Yêu thích',
                  subtitle: 'Sản phẩm đã lưu',
                  badge: authProvider.user?.wishlist.length.toString(),
                  onTap: () {
                    // TODO: Navigate to wishlist
                    print('Wishlist');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Settings
          const Text('Cài đặt', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  subtitle: 'Cài đặt thông báo',
                  onTap: () {
                    // TODO: Navigate to notification settings
                    print('Notifications settings');
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.language_outlined,
                  title: 'Ngôn ngữ',
                  subtitle: 'Tiếng Việt',
                  onTap: () {
                    // TODO: Change language
                    print('Language');
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Giao diện',
                  subtitle: 'Sáng',
                  onTap: () {
                    // TODO: Change theme
                    print('Theme');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Support
          const Text('Hỗ trợ', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Trung tâm hỗ trợ',
                  subtitle: 'FAQ & Hướng dẫn',
                  onTap: () {
                    // TODO: Navigate to help center
                    print('Help center');
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.policy_outlined,
                  title: 'Chính sách',
                  subtitle: 'Điều khoản & Bảo mật',
                  onTap: () {
                    // TODO: Navigate to policies
                    print('Policies');
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: 'Về chúng tôi',
                  subtitle: 'Phiên bản 1.0.0',
                  onTap: () {
                    // TODO: Navigate to about
                    print('About');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            _showLogoutDialog(context, authProvider);
          },
          icon: const Icon(Icons.logout),
          label: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.textHint.withOpacity(0.1),
      indent: 60,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// Stats Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Menu Item Widget
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Badge
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}