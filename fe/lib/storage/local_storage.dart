// lib/storage/local_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _keyToken = 'access_token';
  static const _keyUser = 'user_info';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final s = await _storage.read(key: _keyUser);
    if (s == null) return null;
    return jsonDecode(s);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
