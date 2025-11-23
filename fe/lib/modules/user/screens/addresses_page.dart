// lib/modules/user/screens/addresses_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/address_provider.dart';
import '../../../data/models/address_model.dart';
import 'add_address_page.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({Key? key}) : super(key: key);

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Địa chỉ của tôi', style: AppTextStyles.h2),
      ),
      body: Consumer2<AuthProvider, AddressProvider>(
        builder: (context, authProvider, addressProvider, _) {
          final addresses = authProvider.user?.addresses ?? [];

          if (addressProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (addresses.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                onEdit: () => _editAddress(address),
                onDelete: () => _deleteAddress(address),
                onSetDefault: () => _setDefaultAddress(address),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAddress,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Thêm địa chỉ'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 100,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có địa chỉ',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm địa chỉ để dễ dàng đặt hàng',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Thêm địa chỉ mới
  Future<void> _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAddressPage(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã thêm địa chỉ mới'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ Sửa địa chỉ
  Future<void> _editAddress(AddressModel address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressPage(address: address),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã cập nhật địa chỉ'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ Xóa địa chỉ (với confirmation)
  Future<void> _deleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: Text(
          'Bạn có chắc chắn muốn xóa địa chỉ "${address.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && address.id != null && mounted) {
      final provider = context.read<AddressProvider>();
      final success = await provider.deleteAddress(address.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa địa chỉ'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? '❌ Không thể xóa địa chỉ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ Đặt địa chỉ mặc định
  Future<void> _setDefaultAddress(AddressModel address) async {
    if (address.id == null) return;

    final provider = context.read<AddressProvider>();
    final success = await provider.setDefaultAddress(address.id!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã đặt địa chỉ mặc định'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '❌ Không thể đặt địa chỉ mặc định'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ✅ Address Card Widget
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.fullName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Mặc định',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.phone,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      PopupMenuItem(
                        onTap: onSetDefault,
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Đặt mặc định'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 20, color: AppColors.error),
                          SizedBox(width: 12),
                          Text(
                            'Xóa',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.fullAddress,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}