// lib/modules/auth/providers/auth_provider.dart
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

  Future<bool> login(String email, String password) async {
    try {
      status = AuthStatus.loading;
      notifyListeners();

      final data = await _repo.login(email, password);
      // data should contain accessToken and user
      final token = data['accessToken'] ?? data['token'] ?? data['access_token'];
      final userJson = data['user'] ?? data;
      if (token == null) {
        status = AuthStatus.error;
        message = 'Token missing in response';
        notifyListeners();
        return false;
      }

      await _storage.saveToken(token);
      await _storage.saveUser(userJson as Map<String, dynamic>);

      user = UserModel.fromJson(userJson as Map<String, dynamic>);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.error;
      message = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
  try {
    status = AuthStatus.loading;
    notifyListeners();

    final data = await _repo.register(name, email, password);

    final token = data['accessToken'] ?? data['token'];
    final userJson = data['user'];

    if (token == null || userJson == null) {
      status = AuthStatus.error;
      message = "Dữ liệu trả về không hợp lệ";
      notifyListeners();
      return false;
    }

    await _storage.saveToken(token);
    await _storage.saveUser(userJson);

    user = UserModel.fromJson(userJson);
    status = AuthStatus.authenticated;
    notifyListeners();
    return true;

  } catch (e) {
    status = AuthStatus.error;
    message = e.toString();
    notifyListeners();
    return false;
  }
}


  Future<void> logout() async {
    await _storage.clearAll();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
