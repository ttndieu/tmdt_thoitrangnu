// lib/modules/auth/providers/auth_provider.dart

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

  bool get isAuthenticated => 
      status == AuthStatus.authenticated && user != null;
  
  bool get isAdmin => user?.role == 'admin';
  bool get isUser => user?.role == 'user';

  // CHECK AUTH STATUS
  Future<void> checkAuthStatus() async {
    try {
      print('\n🔐 ========== CHECK AUTH STATUS ==========');
      
      final token = await _storage.getToken();
      final userJson = await _storage.getUser();

      if (token != null && userJson != null) {
        userJson['token'] = token;
        user = UserModel.fromJson(userJson);
        status = AuthStatus.authenticated;
        
        print('✅ User authenticated from storage');
        print('👤 User: ${user?.name}');
        print('📧 Email: ${user?.email}');
      } else {
        status = AuthStatus.unauthenticated;
        print('⚠️ No user in storage');
      }
      
      print('🔐 ========== CHECK AUTH STATUS END ==========\n');
      notifyListeners();
    } catch (e) {
      print('❌ Check auth status error: $e');
      print('🔐 ========== CHECK AUTH STATUS END ==========\n');
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // ========== LOGIN ==========
  Future<bool> login(String email, String password) async {
    try {
      print('\n🔐 ========== LOGIN (FLUTTER) ==========');
      print('📧 Email: $email');

      status = AuthStatus.loading;
      message = null;
      notifyListeners();

      final data = await _repo.login(email, password);

      final token = data["token"] ?? data["accessToken"];
      final userJson = data["user"];

      if (token == null || userJson == null) {
        throw Exception("Dữ liệu trả về không hợp lệ");
      }

      userJson["token"] = token;

      await _storage.saveToken(token);
      await _storage.saveUser(userJson);

      user = UserModel.fromJson(userJson);

      status = AuthStatus.authenticated;
      message = "Đăng nhập thành công";
      
      print('✅ Login successful');
      print('👤 User: ${user?.name}');
      print('🔐 ========== LOGIN END ==========\n');
      
      notifyListeners();
      return true;

    } catch (e) {
      print('❌ Login error: $e');
      print('🔐 ========== LOGIN END ==========\n');

      status = AuthStatus.error;
      
      // ✅ PARSE ERROR MESSAGES
      message = _parseErrorMessage(e);
      
      notifyListeners();
      return false;
    }
  }

  // ========== REGISTER ==========
  Future<bool> register(String name, String email, String password) async {
    try {
      print('\n📝 ========== REGISTER (FLUTTER) ==========');
      print('👤 Name: $name');
      print('📧 Email: $email');

      status = AuthStatus.loading;
      message = null;
      notifyListeners();

      final data = await _repo.register(name, email, password);

      final token = data["token"] ?? data["accessToken"];
      final userJson = data["user"];

      if (token == null || userJson == null) {
        throw Exception("Dữ liệu trả về không hợp lệ");
      }

      userJson["token"] = token;

      await _storage.saveToken(token);
      await _storage.saveUser(userJson);

      user = UserModel.fromJson(userJson);

      status = AuthStatus.authenticated;
      message = "Đăng ký thành công";
      
      print('✅ Register successful');
      print('📝 ========== REGISTER END ==========\n');
      
      notifyListeners();
      return true;

    } catch (e) {
      print('❌ Register error: $e');
      print('📝 ========== REGISTER END ==========\n');

      status = AuthStatus.error;
      
      // ✅ PARSE ERROR MESSAGES
      message = _parseErrorMessage(e);
      
      notifyListeners();
      return false;
    }
  }

  // ✅ HELPER - PARSE ERROR MESSAGES
  String _parseErrorMessage(dynamic error) {
    if (error is DioException) {
      // Network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối bị timeout. Vui lòng thử lại.';
      }
      
      if (error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
      }

      // API errors
      if (error.response?.data != null) {
        final data = error.response!.data;
        
        if (data is Map && data['message'] != null) {
          return data['message'] as String;
        }
      }

      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }

    // Other errors
    final errorString = error.toString();
    
    // Remove "Exception: " prefix
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }
    
    return errorString;
  }

  // ========== UPLOAD AVATAR ==========
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      print('\n📸 ========== UPLOAD AVATAR ==========');

      final token = await _storage.getToken();
      if (token == null) throw 'Không tìm thấy token';

      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.post(
        ApiConfig.UPLOAD_AVATAR,
        data: formData,
      );

      if (response.statusCode == 200) {
        final imageUrl = response.data['imageUrl'];
        print('✅ Upload success: $imageUrl');
        print('📸 ========== UPLOAD AVATAR END ==========\n');
        return imageUrl;
      }

      return null;
    } catch (e) {
      print('❌ Upload avatar error: $e');
      print('📸 ========== UPLOAD AVATAR END ==========\n');
      return null;
    }
  }

  // ========== UPDATE PROFILE ==========
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    try {
      print('\n✏️ ========== UPDATE PROFILE ==========');

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
        userJson['token'] = user?.token;

        await _storage.saveUser(userJson);
        user = UserModel.fromJson(userJson);
        
        print('✅ Profile updated');
        print('✏️ ========== UPDATE PROFILE END ==========\n');
        
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Update profile error: $e');
      message = _parseErrorMessage(e);
      return false;
    }
  }

  // ========== CHANGE PASSWORD ==========
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print('\n🔐 ========== CHANGE PASSWORD ==========');

      final response = await _apiClient.put(
        ApiConfig.USER_CHANGE_PASSWORD,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Password changed');
        print('🔐 ========== CHANGE PASSWORD END ==========\n');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Change password error: $e');
      print('🔐 ========== CHANGE PASSWORD END ==========\n');
      
      throw _parseErrorMessage(e);
    }
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    print('\n👋 ========== LOGOUT ==========');
    
    await _storage.clearAll();
    user = null;
    status = AuthStatus.unauthenticated;
    message = null;
    
    print('✅ Logged out');
    print('👋 ========== LOGOUT END ==========\n');
    
    notifyListeners();
  }
}