// lib/modules/user/providers/voucher_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/voucher_model.dart';

class VoucherProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<VoucherModel> _vouchers = [];
  VoucherModel? _appliedVoucher;
  bool _isLoading = false;
  String? _error;

  List<VoucherModel> get vouchers => _vouchers;
  List<VoucherModel> get availableVouchers => 
      _vouchers.where((v) => v.isAvailable).toList();
  VoucherModel? get appliedVoucher => _appliedVoucher;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ Fetch tất cả vouchers
  Future<void> fetchVouchers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.VOUCHERS);

      if (response.statusCode == 200) {
        final data = response.data;
        _vouchers = (data['vouchers'] as List)
            .map((json) => VoucherModel.fromJson(json))
            .toList();
        
        // Sắp xếp: available trước, expired sau
        _vouchers.sort((a, b) {
          if (a.isAvailable && !b.isAvailable) return -1;
          if (!a.isAvailable && b.isAvailable) return 1;
          return b.expiredAt.compareTo(a.expiredAt);
        });
      }
    } catch (e) {
      _error = 'Không thể tải danh sách voucher';
      print('❌ Fetch vouchers error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Apply voucher (validate)
  Future<Map<String, dynamic>?> applyVoucher({
    required String code,
    required double totalAmount,
  }) async {
    _error = null;
    
    try {
      final response = await _apiClient.post(
        ApiConfig.APPLY_VOUCHER,
        data: {
          'code': code,
          'totalAmount': totalAmount,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Tìm voucher trong danh sách
        _appliedVoucher = _vouchers.firstWhere(
          (v) => v.code == code,
          orElse: () => VoucherModel(
            id: '',
            code: code,
            discountPercent: 0,
            maxDiscount: data['discount'] ?? 0,
            minOrderValue: 0,
            quantity: 0,
            expiredAt: DateTime.now(),
            active: true,
          ),
        );
        
        notifyListeners();
        
        return {
          'success': true,
          'discount': data['discount'] ?? 0,
          'finalPrice': data['finalPrice'] ?? totalAmount,
        };
      }
    } catch (e) {
      _error = _parseError(e.toString());
      print('❌ Apply voucher error: $e');
    }
    
    return null;
  }

  // ✅ Remove applied voucher
  void removeVoucher() {
    _appliedVoucher = null;
    _error = null;
    notifyListeners();
  }

  // ✅ Refresh
  Future<void> refresh() async {
    await fetchVouchers();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseError(String error) {
    if (error.contains('không tồn tại')) {
      return 'Mã voucher không tồn tại';
    } else if (error.contains('đã bị khóa')) {
      return 'Mã voucher đã bị vô hiệu hóa';
    } else if (error.contains('hết hạn')) {
      return 'Mã voucher đã hết hạn';
    } else if (error.contains('phải từ')) {
      return 'Đơn hàng chưa đủ điều kiện áp dụng';
    } else if (error.contains('hết lượt')) {
      return 'Mã voucher đã hết lượt sử dụng';
    }
    return 'Không thể áp dụng mã voucher';
  }
}