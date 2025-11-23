import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fe/core/config/api.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../storage/local_storage.dart';
import '../../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, error, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final LocalStorage _storage = LocalStorage();
  final ApiClient _apiClient = ApiClient();

  AuthStatus status = AuthStatus.initial;
  String? message;
  UserModel? user;

  // ========== LOGIN ==========
  Future<bool> login(String email, String password) async {
    try {
      status = AuthStatus.loading;
      notifyListeners();

      final data = await _repo.login(email, password);

      final token = data["token"] ?? data["accessToken"];
      final userJson = data["user"];

      if (token == null || userJson == null) {
        status = AuthStatus.error;
        message = "Token hoặc User không hợp lệ từ server";
        notifyListeners();
        return false;
      }

      // Thêm token vào userJson để UserModel khởi tạo được
      userJson["token"] = token;

      // Lưu storage
      await _storage.saveToken(token);
      await _storage.saveUser(userJson);

      // Parse model
      user = UserModel.fromJson(userJson);

      status = AuthStatus.authenticated;
      notifyListeners();
      return true;

    } catch (e) {
      message = e.toString();
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ========== REGISTER ==========
  Future<bool> register(String name, String email, String password) async {
    try {
      status = AuthStatus.loading;
      notifyListeners();

      final data = await _repo.register(name, email, password);

      final token = data["token"] ?? data["accessToken"];
      final userJson = data["user"];

      if (token == null || userJson == null) {
        status = AuthStatus.error;
        message = "Dữ liệu trả về không hợp lệ";
        notifyListeners();
        return false;
      }

      // Thêm token
      userJson["token"] = token;

      await _storage.saveToken(token);
      await _storage.saveUser(userJson);

      user = UserModel.fromJson(userJson);

      status = AuthStatus.authenticated;
      notifyListeners();
      return true;

    } catch (e) {
      message = e.toString();
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      print('\n📸 ========== UPLOAD AVATAR (FLUTTER) ==========');
      print('📁 File path: ${imageFile.path}');

      final token = await _storage.getToken();
      if (token == null) {
        throw 'Không tìm thấy token';
      }

      // Tạo FormData với Dio
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      print('📤 Uploading to: ${ApiConfig.UPLOAD_AVATAR}');

      // Upload với Dio
      final response = await _apiClient.post(
        ApiConfig.UPLOAD_AVATAR,
        data: formData,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final imageUrl = response.data['imageUrl'];
        
        print('✅ Upload success');
        print('🖼️ Image URL: $imageUrl');
        print('📸 ========== UPLOAD AVATAR END ==========\n');
        
        return imageUrl;
      }

      print('❌ Upload failed with status: ${response.statusCode}');
      return null;

    } catch (e) {
      print('❌ Upload avatar error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    try {
      print('\n✏️ ========== UPDATE PROFILE (FLUTTER) ==========');
      print('📝 Name: $name');
      print('📞 Phone: ${phone ?? "None"}');
      print('🖼️ Avatar: ${avatar ?? "None"}');

      final response = await _apiClient.put(
        ApiConfig.USER_UPDATE,
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
        },
      );

      if (response.statusCode == 200) {
        final userJson = response.data['user'];
        userJson['token'] = user?.token; // Giữ lại token cũ

        // Cập nhật storage
        await _storage.saveUser(userJson);

        // Cập nhật user model
        user = UserModel.fromJson(userJson);
        
        print('✅ Profile updated successfully');
        print('✏️ ========== UPDATE PROFILE END ==========\n');
        
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Update profile error: $e');
      message = e.toString();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print('\n🔐 ========== CHANGE PASSWORD (FLUTTER) ==========');

      final response = await _apiClient.put(
        '${ApiConfig.BASE_URL}/user/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Password changed successfully');
        print('🔐 ========== CHANGE PASSWORD END ==========\n');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Change password error: $e');
      
      // Extract error message
      if (e.toString().contains('Mật khẩu cũ không chính xác')) {
        throw 'Mật khẩu cũ không chính xác';
      } else if (e.toString().contains('Mật khẩu mới phải có ít nhất')) {
        throw 'Mật khẩu mới phải có ít nhất 6 ký tự';
      }
      
      throw 'Không thể đổi mật khẩu. Vui lòng thử lại';
    }
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    await _storage.clearAll();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
