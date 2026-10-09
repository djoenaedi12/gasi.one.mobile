import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/cubits/categories_cubit.dart';

void main() {
  test('reloads server pagination after create, update and delete', () async {
    final repository = _FakeCategoryRepository(count: 12);
    final cubit = CategoriesCubit(repository);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.items, hasLength(10));
    expect(cubit.state.hasMore, isTrue);
    expect(repository.requestedPages, [0]);

    await cubit.loadMore();

    expect(cubit.state.items, hasLength(12));
    expect(cubit.state.hasMore, isFalse);
    expect(repository.requestedPages, [0, 1]);

    const draft = CategoryDraft(
      code: 'NEW',
      name: 'New category',
      description: 'New description',
    );
    expect(await cubit.create(draft), isTrue);
    expect(cubit.state.items.first.code, 'NEW');

    final original = cubit.state.items.last;
    const update = CategoryDraft(
      code: 'UPDATED',
      name: 'Updated category',
      description: 'Updated description',
    );
    expect(await cubit.update(original, update), isTrue);
    expect(cubit.state.items.last.code, 'UPDATED');

    final created = cubit.state.items.first;
    expect(await cubit.delete(created), isTrue);
    expect(
      cubit.state.items.any((category) => category.id == created.id),
      isFalse,
    );
  });
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository({required int count})
    : _categories = [
        for (var index = 0; index < count; index++)
          Category(
            id: '${index + 1}',
            code: 'CAT-${index + 1}',
            name: 'Category ${index + 1}',
            description: 'Description ${index + 1}',
          ),
      ];

  final List<Category> _categories;
  final List<int> requestedPages = [];
  var _nextId = 100;

  @override
  Future<Result<PageResult<Category>>> queryPage(QueryRequest query) async {
    final page = query.normalizedPage;
    final size = query.normalizedSize;
    requestedPages.add(page);
    final start = page * size;
    final end = (start + size).clamp(0, _categories.length);
    final content = start >= _categories.length
        ? <Category>[]
        : _categories.sublist(start, end);

    return Success(
      PageResult(
        content: content,
        page: page,
        size: size,
        totalElements: _categories.length,
        totalPages: (_categories.length / size).ceil(),
      ),
    );
  }

  @override
  Future<Result<Category>> create(CategoryDraft draft) async {
    final category = _fromDraft('${_nextId++}', draft);
    _categories.insert(0, category);
    return Success(category);
  }

  @override
  Future<Result<Category>> update(String id, CategoryDraft draft) async {
    final category = _fromDraft(id, draft);
    final index = _categories.indexWhere((item) => item.id == id);
    _categories[index] = category;
    return Success(category);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _categories.removeWhere((category) => category.id == id);
    return const Success(null);
  }

  @override
  Future<Result<Category>> getById(String id) async {
    return Success(_categories.firstWhere((category) => category.id == id));
  }

  @override
  Future<Result<List<Category>>> queryList(QueryRequest query) async {
    return Success(List.unmodifiable(_categories));
  }

  @override
  Future<Result<Category?>> queryOne(QueryRequest query) async {
    return Success(_categories.firstOrNull);
  }

  Category _fromDraft(String id, CategoryDraft draft) {
    return Category(
      id: id,
      code: draft.code,
      name: draft.name,
      description: draft.description,
    );
  }
}
