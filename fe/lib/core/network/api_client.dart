// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import '../../storage/local_storage.dart';
import '../config/api.dart';

class ApiClient {
  final Dio dio;
  final LocalStorage storage = LocalStorage();

  ApiClient._internal(this.dio) {
    dio.options.baseUrl = ApiConfig.BASE_URL;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Mặc định JSON nếu không phải multipart
          options.headers['Content-Type'] =
              options.headers['Content-Type'] ?? 'application/json';

          return handler.next(options);
        },
        onError: (e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal(Dio());
  factory ApiClient() => _instance;

  // ============================
  //   METHODS ĐÃ FIX HỖ TRỢ OPTIONS
  // ============================

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.put(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.delete(
      path,
      data: data,
      options: options,
    );
  }
}
