// lib/data/repositories/auth_repository.dart
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api.dart';

class AuthRepository {
  final ApiClient apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await apiClient.post(ApiConfig.AUTH_LOGIN, data: {
      'email': email,
      'password': password,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final resp = await apiClient.post(ApiConfig.AUTH_REGISTER, data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return resp.data as Map<String, dynamic>;
  }

  
}
