import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  test(
    'orchestrates pagination and CRUD without a feature-specific Cubit',
    () async {
      final repository = _FakeCrudRepository();
      final cubit =
          PaginatedCrudCubit<
            _Item,
            int,
            _Query,
            _PageQuery,
            _PageResponse,
            _Draft,
            _Draft
          >(
            repository: repository,
            initialPageQuery: const _PageQuery(0),
            idOf: (item) => item.id,
            mapPage: (response) => CrudPageData(
              items: response.items,
              total: response.total,
              nextPageQuery: response.nextOffset == null
                  ? null
                  : _PageQuery(response.nextOffset!),
            ),
          );
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.items.map((item) => item.id), [1, 2]);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items.map((item) => item.id), [1, 2, 3]);
      expect(cubit.state.hasMore, isFalse);

      expect(await cubit.create(const _Draft('Created')), isTrue);
      final created = cubit.state.items.first;
      expect(created.name, 'Created');

      expect(await cubit.update(created, const _Draft('Updated')), isTrue);
      expect(cubit.state.items.first.name, 'Updated');

      expect(await cubit.delete(cubit.state.items.first), isTrue);
      expect(cubit.state.items.any((item) => item.name == 'Updated'), isFalse);
    },
  );

  test(
    'standard Cubit derives the next QueryRequest from PageResult',
    () async {
      final repository = _StandardFakeCrudRepository();
      final cubit = BaseCrudCubit<_Item, int, _Draft, _Draft>(
        repository: repository,
        initialQuery: const QueryRequest(
          sorts: [SortOrder.desc('createdAt')],
          size: 2,
        ),
        idOf: (item) => item.id,
      );
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      expect(repository.pages, [0, 1]);
      expect(repository.sizes, [2, 2]);
      expect(cubit.state.items.map((item) => item.id), [1, 2, 3]);
      expect(cubit.state.hasMore, isFalse);
    },
  );
}

class _Item {
  const _Item(this.id, this.name);

  final int id;
  final String name;
}

class _Draft {
  const _Draft(this.name);

  final String name;
}

class _Query {
  const _Query();
}

class _PageQuery {
  const _PageQuery(this.offset);

  final int offset;
}

class _PageResponse {
  const _PageResponse({
    required this.items,
    required this.total,
    required this.nextOffset,
  });

  final List<_Item> items;
  final int total;
  final int? nextOffset;
}

class _FakeCrudRepository
    implements
        BaseCrudRepository<
          _Item,
          int,
          _Query,
          _PageQuery,
          _PageResponse,
          _Draft,
          _Draft
        > {
  final List<_Item> _items = const [
    _Item(1, 'One'),
    _Item(2, 'Two'),
    _Item(3, 'Three'),
  ].toList();

  @override
  Future<Result<_Item>> create(_Draft draft) async {
    final item = _Item(100, draft.name);
    _items.insert(0, item);
    return Success(item);
  }

  @override
  Future<Result<void>> delete(int id) async {
    _items.removeWhere((item) => item.id == id);
    return const Success(null);
  }

  @override
  Future<Result<_Item>> getById(int id) async {
    return Success(_items.firstWhere((item) => item.id == id));
  }

  @override
  Future<Result<List<_Item>>> queryList(_Query query) async {
    return Success(List.unmodifiable(_items));
  }

  @override
  Future<Result<_Item?>> queryOne(_Query query) async {
    return Success(_items.isEmpty ? null : _items.first);
  }

  @override
  Future<Result<_PageResponse>> queryPage(_PageQuery query) async {
    const pageSize = 2;
    final end = (query.offset + pageSize).clamp(0, _items.length);
    final items = _items.sublist(query.offset, end);
    return Success(
      _PageResponse(
        items: items,
        total: _items.length,
        nextOffset: end < _items.length ? end : null,
      ),
    );
  }

  @override
  Future<Result<_Item>> update(int id, _Draft draft) async {
    final index = _items.indexWhere((item) => item.id == id);
    final item = _Item(id, draft.name);
    _items[index] = item;
    return Success(item);
  }
}

class _StandardFakeCrudRepository
    implements
        BaseCrudRepository<
          _Item,
          int,
          QueryRequest,
          QueryRequest,
          PageResult<_Item>,
          _Draft,
          _Draft
        > {
  final List<int> pages = [];
  final List<int> sizes = [];

  @override
  Future<Result<PageResult<_Item>>> queryPage(QueryRequest query) async {
    pages.add(query.page);
    sizes.add(query.size);
    return Success(
      PageResult(
        content: query.page == 0
            ? const [_Item(1, 'One'), _Item(2, 'Two')]
            : const [_Item(3, 'Three')],
        page: query.page,
        size: query.size,
        totalElements: 3,
        totalPages: 2,
      ),
    );
  }

  @override
  Future<Result<_Item>> create(_Draft draft) => throw UnimplementedError();

  @override
  Future<Result<void>> delete(int id) => throw UnimplementedError();

  @override
  Future<Result<_Item>> getById(int id) => throw UnimplementedError();

  @override
  Future<Result<List<_Item>>> queryList(QueryRequest query) =>
      throw UnimplementedError();

  @override
  Future<Result<_Item?>> queryOne(QueryRequest query) =>
      throw UnimplementedError();

  @override
  Future<Result<_Item>> update(int id, _Draft draft) =>
      throw UnimplementedError();
}
