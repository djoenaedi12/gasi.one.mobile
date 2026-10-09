import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/repositories/product_repository.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/cubits/products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository, {this.reloadAfterMutation = true})
    : super(ProductsState.initial());

  static const pageSize = 10;

  final ProductRepository _repository;
  final bool reloadAfterMutation;
  int _generation = 0;

  /// Loads the first page. Also used by pull-to-refresh.
  Future<void> load() async {
    if (isClosed || state.isMutating) {
      return;
    }

    final generation = ++_generation;
    final current = state;
    emit(
      ProductsState(
        status: ProductsStatus.loading,
        products: current.products,
        total: current.total,
        nextSkip: current.nextSkip,
        hasMore: current.hasMore,
      ),
    );

    final result = await _repository.getProducts(limit: pageSize, skip: 0);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        emit(
          ProductsState(
            status: ProductsStatus.ready,
            products: data.items,
            total: data.total,
            nextSkip: data.nextOffset,
            hasMore: data.hasMore,
          ),
        );
      case FailureResult(:final failure):
        emit(
          ProductsState(
            status: ProductsStatus.failure,
            products: current.products,
            total: current.total,
            nextSkip: current.nextSkip,
            hasMore: current.hasMore,
            error: failure,
          ),
        );
    }
  }

  /// Appends the next server page while preserving the visible list.
  Future<void> loadMore() => _loadMore();

  /// Retries a failed load-more request after explicit user interaction.
  Future<void> retryLoadMore() => _loadMore(retry: true);

  Future<void> _loadMore({bool retry = false}) async {
    if (_isBusy || !state.hasMore || (state.loadMoreError != null && !retry)) {
      return;
    }

    final current = state;
    emit(
      ProductsState(
        status: ProductsStatus.loadingMore,
        products: current.products,
        total: current.total,
        nextSkip: current.nextSkip,
        hasMore: current.hasMore,
      ),
    );

    final generation = _generation;
    final result = await _repository.getProducts(
      limit: pageSize,
      skip: current.nextSkip,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        final existingIds = current.products.map((item) => item.id).toSet();
        final products = [
          ...current.products,
          for (final item in data.items)
            if (existingIds.add(item.id)) item,
        ];
        emit(
          ProductsState(
            status: ProductsStatus.ready,
            products: products,
            total: data.total,
            nextSkip: data.nextOffset,
            hasMore: data.hasMore,
          ),
        );
      case FailureResult(:final failure):
        emit(
          ProductsState(
            status: ProductsStatus.ready,
            products: current.products,
            total: current.total,
            nextSkip: current.nextSkip,
            hasMore: current.hasMore,
            loadMoreError: failure,
          ),
        );
    }
  }

  Future<bool> add(ProductDraft draft) async {
    return _mutate(() async {
      final result = await _repository.addProduct(draft);
      return switch (result) {
        Success(:final data) => Success([data, ...state.products]),
        FailureResult(:final failure) => FailureResult(failure),
      };
    });
  }

  Future<bool> update(Product product, ProductDraft draft) async {
    return _mutate(() async {
      final result = await _repository.updateProduct(product.id, draft);
      return switch (result) {
        Success(:final data) => Success([
          for (final item in state.products)
            if (item.id == product.id) data else item,
        ]),
        FailureResult(:final failure) => FailureResult(failure),
      };
    });
  }

  Future<bool> delete(Product product) async {
    return _mutate(() async {
      final result = await _repository.deleteProduct(product.id);
      return switch (result) {
        Success() => Success(
          state.products.where((item) => item.id != product.id).toList(),
        ),
        FailureResult(:final failure) => FailureResult(failure),
      };
    });
  }

  Future<bool> _mutate(
    Future<Result<List<Product>>> Function() operation,
  ) async {
    if (_isBusy) {
      return false;
    }

    final current = state;
    emit(
      ProductsState(
        status: ProductsStatus.mutating,
        products: current.products,
        total: current.total,
        nextSkip: current.nextSkip,
        hasMore: current.hasMore,
      ),
    );

    final result = await operation();
    if (isClosed) return result is Success;
    switch (result) {
      case Success(:final data):
        if (reloadAfterMutation) {
          await _reloadAfterMutation();
          return true;
        }
        emit(
          ProductsState(
            status: ProductsStatus.ready,
            products: data,
            total: current.total,
            nextSkip: current.nextSkip,
            hasMore: current.hasMore,
          ),
        );
        return true;
      case FailureResult(:final failure):
        emit(
          ProductsState(
            status: ProductsStatus.failure,
            products: current.products,
            total: current.total,
            nextSkip: current.nextSkip,
            hasMore: current.hasMore,
            error: failure,
          ),
        );
        return false;
    }
  }

  Future<void> _reloadAfterMutation() async {
    final result = await _repository.getProducts(limit: pageSize, skip: 0);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          ProductsState(
            status: ProductsStatus.ready,
            products: data.items,
            total: data.total,
            nextSkip: data.nextOffset,
            hasMore: data.hasMore,
          ),
        );
      case FailureResult(:final failure):
        emit(ProductsState(status: ProductsStatus.failure, error: failure));
    }
  }

  bool get _isBusy => isClosed || state.isBusy;
}
