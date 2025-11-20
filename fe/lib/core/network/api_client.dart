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

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (e, handler) {
        // you can parse error here
        return handler.next(e);
      },
    ));
  }

  static final ApiClient _instance = ApiClient._internal(Dio());
  factory ApiClient() => _instance;

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return dio.delete(path, data: data);
  }
}
