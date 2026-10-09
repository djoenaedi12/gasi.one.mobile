import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/picker/category_picker_cubit.dart';

const _travel = Category(
  id: 'travel',
  code: 'TRAVEL',
  name: 'Travel',
  description: '',
);

void main() {
  testWidgets('server search is debounced and ignores older results', (
    tester,
  ) async {
    final repository = _Repository();
    final cubit = CategoryPickerCubit(repository);
    addTearDown(cubit.close);
    final initial = cubit.load();
    cubit.search('T');
    await tester.pump(const Duration(milliseconds: 100));
    cubit.search('Travel');
    await tester.pump(const Duration(milliseconds: 301));
    expect(repository.queries, hasLength(2));
    expect(repository.queries.last.size, 20);
    expect(repository.queries.last.filter!.toJson()['filters'], [
      {
        'type': 'simple',
        'field': 'code',
        'operator': 'LIKE',
        'value': '%Travel%',
      },
      {
        'type': 'simple',
        'field': 'name',
        'operator': 'LIKE',
        'value': '%Travel%',
      },
    ]);
    repository.responses.last.complete(Success(_page([_travel])));
    await tester.pump();
    repository.responses.first.complete(Success(_page([])));
    await initial;
    expect(cubit.state.items.single.id, 'travel');
  });
  test(
    'load more preserves server filters and supports failure retry',
    () async {
      final repository = _Repository();
      final cubit = CategoryPickerCubit(repository);
      addTearDown(cubit.close);
      final loading = cubit.load();
      repository.responses.last.complete(
        Success(_page([_travel], totalPages: 2)),
      );
      await loading;
      final more = cubit.loadMore();
      expect(repository.queries.last.page, 1);
      repository.responses.last.complete(const FailureResult(NetworkFailure()));
      await more;
      expect(cubit.state.items.single.id, 'travel');
      await cubit.loadMore();
      expect(repository.queries, hasLength(2));
      final retry = cubit.loadMore(retry: true);
      repository.responses.last.complete(
        Success(_page([_travel], page: 1, totalPages: 2)),
      );
      await retry;
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.hasMore, isFalse);
    },
  );
  test('closing picker ignores pending results', () async {
    final repository = _Repository();
    final cubit = CategoryPickerCubit(repository);
    final pending = cubit.load();
    await cubit.close();
    repository.responses.single.complete(Success(_page([_travel])));
    await pending;
  });
}

PageResult<Category> _page(
  List<Category> content, {
  int page = 0,
  int totalPages = 1,
}) => PageResult(
  content: content,
  page: page,
  size: 20,
  totalElements: 21,
  totalPages: totalPages,
);

class _Repository implements CategoryRepository {
  final queries = <QueryRequest>[];
  final responses = <Completer<Result<PageResult<Category>>>>[];
  @override
  Future<Result<PageResult<Category>>> queryPage(QueryRequest query) {
    queries.add(query);
    final response = Completer<Result<PageResult<Category>>>();
    responses.add(response);
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
