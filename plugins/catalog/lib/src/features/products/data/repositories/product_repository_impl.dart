import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/products/data/datasources/product_remote_data_source.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<Result<PaginatedPage<Product>>> getProducts({
    required int limit,
    required int skip,
  }) {
    return guardResult(() async {
      final response = await _remoteDataSource.getProducts(
        limit: limit,
        skip: skip,
      );
      return PaginatedPage(
        items: response.products
            .map((model) => model.toEntity())
            .toList(growable: false),
        total: response.total,
        offset: response.skip,
        limit: response.limit,
      );
    });
  }

  @override
  Future<Result<Product>> addProduct(ProductDraft draft) {
    return guardResult(() async {
      final model = await _remoteDataSource.addProduct(draft);
      return model.toEntity();
    });
  }

  @override
  Future<Result<Product>> updateProduct(int id, ProductDraft draft) {
    return guardResult(() async {
      final model = await _remoteDataSource.updateProduct(id, draft);
      return model.toEntity();
    });
  }

  @override
  Future<Result<void>> deleteProduct(int id) {
    return guardResult(() async {
      await _remoteDataSource.deleteProduct(id);
    });
  }
}
