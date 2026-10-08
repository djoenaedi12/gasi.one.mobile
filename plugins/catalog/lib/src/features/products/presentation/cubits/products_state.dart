import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';

enum ProductsStatus { initial, loading, ready, loadingMore, mutating, failure }

class ProductsState {
  ProductsState({
    required this.status,
    List<Product> products = const [],
    this.total = 0,
    this.nextSkip = 0,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
  }) : products = List.unmodifiable(products);

  factory ProductsState.initial() {
    return ProductsState(status: ProductsStatus.initial);
  }

  final ProductsStatus status;
  final List<Product> products;
  final int total;
  final int nextSkip;
  final bool hasMore;
  final Failure? error;
  final Failure? loadMoreError;

  bool get isLoading => status == ProductsStatus.loading;
  bool get isLoadingMore => status == ProductsStatus.loadingMore;
  bool get isMutating => status == ProductsStatus.mutating;
  bool get isBusy => isLoading || isLoadingMore || isMutating;
}
