import 'package:dio/dio.dart';
import '../../core/config/api.dart';
import '../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ApiClient api = ApiClient();

  Future<List<ProductModel>> getProducts() async {
    Response resp = await api.get(ApiConfig.PRODUCTS);

    final List list = resp.data["products"] ?? resp.data;
    
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }
}
