import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/repositories/product_repository.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/cubits/products_cubit.dart';

void main() {
  test(
    'loads and applies create, update, and delete results locally',
    () async {
      final cubit = ProductsCubit(_FakeProductRepository(productCount: 1));
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.products.single.title, 'Original');

      const createdDraft = ProductDraft(
        title: 'Created',
        description: 'New product',
        category: 'demo',
        price: 20,
        stock: 5,
      );
      expect(await cubit.add(createdDraft), isTrue);
      expect(cubit.state.products.first.title, 'Created');

      const updatedDraft = ProductDraft(
        title: 'Updated',
        description: 'Updated product',
        category: 'demo',
        price: 25,
        stock: 3,
      );
      final original = cubit.state.products.last;
      expect(await cubit.update(original, updatedDraft), isTrue);
      expect(cubit.state.products.last.title, 'Updated');

      final created = cubit.state.products.first;
      expect(await cubit.delete(created), isTrue);
      expect(
        cubit.state.products.any((product) => product.id == created.id),
        isFalse,
      );
    },
  );

  test('loads ten products at a time until all pages are exhausted', () async {
    final repository = _FakeProductRepository(productCount: 25);
    final cubit = ProductsCubit(repository);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.products, hasLength(10));
    expect(cubit.state.nextSkip, 10);
    expect(cubit.state.hasMore, isTrue);
    expect(repository.requestedSkips, [0]);

    await cubit.loadMore();

    expect(cubit.state.products, hasLength(20));
    expect(cubit.state.nextSkip, 20);
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();

    expect(cubit.state.products, hasLength(25));
    expect(cubit.state.nextSkip, 25);
    expect(cubit.state.hasMore, isFalse);
    expect(repository.requestedSkips, [0, 10, 20]);

    await cubit.loadMore();
    expect(repository.requestedSkips, [0, 10, 20]);
  });

  test('keeps loaded products and supports explicit load-more retry', () async {
    final repository = _FakeProductRepository(productCount: 25);
    final cubit = ProductsCubit(repository);
    addTearDown(cubit.close);

    await cubit.load();
    repository.failNextRequest = true;
    await cubit.loadMore();

    expect(cubit.state.products, hasLength(10));
    expect(cubit.state.loadMoreError, isA<NetworkFailure>());

    await cubit.loadMore();
    expect(repository.requestedSkips, [0, 10]);

    await cubit.retryLoadMore();
    expect(cubit.state.products, hasLength(20));
    expect(cubit.state.loadMoreError, isNull);
    expect(repository.requestedSkips, [0, 10, 10]);
  });
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository({required this.productCount});

  final int productCount;
  final List<int> requestedSkips = [];
  bool failNextRequest = false;

  @override
  Future<Result<PaginatedPage<Product>>> getProducts({
    required int limit,
    required int skip,
  }) async {
    requestedSkips.add(skip);
    if (failNextRequest) {
      failNextRequest = false;
      return const FailureResult(NetworkFailure());
    }
    final end = (skip + limit).clamp(0, productCount);
    final items = [
      for (var index = skip; index < end; index++)
        Product(
          id: index + 1,
          title: index == 0 ? 'Original' : 'Product ${index + 1}',
          description: 'Product description',
          category: 'demo',
          price: 10,
          stock: 10,
          thumbnailUrl: '',
        ),
    ];
    return Success(
      PaginatedPage(
        items: items,
        total: productCount,
        offset: skip,
        limit: limit,
      ),
    );
  }

  @override
  Future<Result<Product>> addProduct(ProductDraft draft) async {
    return Success(_fromDraft(195, draft));
  }

  @override
  Future<Result<Product>> updateProduct(int id, ProductDraft draft) async {
    return Success(_fromDraft(id, draft));
  }

  @override
  Future<Result<void>> deleteProduct(int id) async {
    return const Success(null);
  }

  Product _fromDraft(int id, ProductDraft draft) {
    return Product(
      id: id,
      title: draft.title,
      description: draft.description,
      category: draft.category,
      price: draft.price,
      stock: draft.stock,
      thumbnailUrl: '',
    );
  }
}
