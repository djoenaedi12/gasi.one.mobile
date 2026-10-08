import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/products/data/models/product_model.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';

class ProductRemoteDataSource {
  const ProductRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ProductListResponseModel> getProducts({
    required int limit,
    required int skip,
  }) async {
    final json = await _apiClient.getJson(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return ApiResponseParser.object(json, ProductListResponseModel.fromJson);
  }

  Future<ProductModel> addProduct(ProductDraft draft) async {
    final json = await _apiClient.postJson(
      '/products/add',
      data: _draftToJson(draft),
    );
    return ApiResponseParser.object(json, ProductModel.fromJson);
  }

  Future<ProductModel> updateProduct(int id, ProductDraft draft) async {
    final json = await _apiClient.putJson(
      '/products/$id',
      data: _draftToJson(draft),
    );
    return ApiResponseParser.object(json, ProductModel.fromJson);
  }

  Future<void> deleteProduct(int id) async {
    await _apiClient.deleteJson('/products/$id');
  }

  Map<String, Object?> _draftToJson(ProductDraft draft) {
    return {
      'title': draft.title,
      'description': draft.description,
      'category': draft.category,
      'price': draft.price,
      'stock': draft.stock,
    };
  }
}
