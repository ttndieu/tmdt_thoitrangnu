// lib/modules/user/providers/address_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../../../data/models/address_model.dart';
import '../../auth/providers/auth_provider.dart';

class AddressProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final AuthProvider _authProvider;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressProvider(this._authProvider);

  List<AddressModel> get addresses => _authProvider.user?.addresses ?? [];
  
  AddressModel? get defaultAddress => _authProvider.user?.defaultAddress;

  // ✅ Thêm địa chỉ mới
  Future<bool> addAddress(AddressModel address) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiClient.post(
        ApiConfig.USER_ADDRESS,
        data: address.toJson(),
      );

      if (response.statusCode == 200) {
        // Cập nhật addresses trong user
        final List addressesJson = response.data['addresses'] ?? [];
        final newAddresses = addressesJson
            .map((json) => AddressModel.fromJson(json))
            .toList();
        
        // Update user addresses
        _authProvider.user = _authProvider.user!.copyWith(
          addresses: newAddresses,
        );
        
        print('✅ Address added successfully');
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Không thể thêm địa chỉ';
      print('❌ Error adding address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Xóa địa chỉ
  Future<bool> deleteAddress(String addressId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiClient.delete(
        '${ApiConfig.USER_ADDRESS}/$addressId',
      );

      if (response.statusCode == 200) {
        final List addressesJson = response.data['addresses'] ?? [];
        final newAddresses = addressesJson
            .map((json) => AddressModel.fromJson(json))
            .toList();
        
        _authProvider.user = _authProvider.user!.copyWith(
          addresses: newAddresses,
        );
        
        print('✅ Address deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Không thể xóa địa chỉ';
      print('❌ Error deleting address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Cập nhật địa chỉ (thực tế backend chưa có, tạm thời xóa rồi thêm mới)
  Future<bool> updateAddress(String addressId, AddressModel address) async {
    try {
      // Vì backend chưa có API update, ta có thể:
      // 1. Xóa địa chỉ cũ
      await deleteAddress(addressId);
      // 2. Thêm địa chỉ mới
      return await addAddress(address);
    } catch (e) {
      _error = 'Không thể cập nhật địa chỉ';
      print('❌ Error updating address: $e');
      return false;
    }
  }

  // ✅ Đặt địa chỉ mặc định (cần backend hỗ trợ)
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Gọi API set default khi backend có
      // Tạm thời update local
      final updatedAddresses = addresses.map((addr) {
        return addr.copyWith(isDefault: addr.id == addressId);
      }).toList();

      _authProvider.user = _authProvider.user!.copyWith(
        addresses: updatedAddresses,
      );

      return true;
    } catch (e) {
      _error = 'Không thể đặt địa chỉ mặc định';
      print('❌ Error setting default address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}