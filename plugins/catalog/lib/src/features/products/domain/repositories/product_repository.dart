import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';

abstract interface class ProductRepository {
  Future<Result<PaginatedPage<Product>>> getProducts({
    required int limit,
    required int skip,
  });

  Future<Result<Product>> addProduct(ProductDraft draft);

  Future<Result<Product>> updateProduct(int id, ProductDraft draft);

  Future<Result<void>> deleteProduct(int id);
}
