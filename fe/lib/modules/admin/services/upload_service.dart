// lib/modules/admin/services/upload_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class UploadService {
  final Dio dio;

  // Pass ApiClient instance so token interceptor được dùng
  UploadService(ApiClient apiClient) : dio = apiClient.dio;

  /// Upload single image. Returns map like { "url": "...", "public_id": "..." }
  Future<Map<String, dynamic>> uploadImage({
    required File file,
    String? categorySlug,
  }) async {
    final filename = file.path.split('/').last;

    MultipartFile multipart;
    if (kIsWeb) {
      // on web: read bytes and use fromBytes
      final bytes = await file.readAsBytes();
      multipart = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      // mobile: fromFile
      multipart = await MultipartFile.fromFile(file.path, filename: filename);
    }

    final form = FormData.fromMap({
      "image": multipart,
      "categorySlug": categorySlug ?? "",
    });

    final res = await dio.post("/api/upload", data: form);
    // backend returns { url, public_id, folder }
    return Map<String, dynamic>.from(res.data);
  }

  Future<bool> deleteImage(String publicId) async {
    final res = await dio.delete("/api/upload/$publicId");
    return res.data != null && (res.data["message"] == "Image deleted" || res.statusCode == 200);
  }

  Future<Map<String, dynamic>> replaceImage({
    required String oldPublicId,
    required File file,
    String? categorySlug,
  }) async {
    final filename = file.path.split('/').last;

    MultipartFile multipart;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      multipart = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      multipart = await MultipartFile.fromFile(file.path, filename: filename);
    }

    final form = FormData.fromMap({
      "old_public_id": oldPublicId,
      "categorySlug": categorySlug ?? "",
      "image": multipart,
    });

    final res = await dio.put("/api/upload/replace", data: form);
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<dynamic>> listImages({required String folder}) async {
    final res = await dio.get("/api/upload/list", queryParameters: {"folder": folder});
    final images = res.data?["images"];
    if (images is List) return images;
    return [];
  }
}
