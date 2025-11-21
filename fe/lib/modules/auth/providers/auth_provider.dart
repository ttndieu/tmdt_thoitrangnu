import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../storage/local_storage.dart';
import '../../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, error, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final LocalStorage _storage = LocalStorage();

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

  // ========== LOGOUT ==========
  Future<void> logout() async {
    await _storage.clearAll();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
