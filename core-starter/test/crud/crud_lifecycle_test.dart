import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  BaseCrudCubit<int, int, int, int> cubit(_Repository repository) =>
      BaseCrudCubit(
        repository: repository,
        initialQuery: const QueryRequest(size: 2),
        idOf: (item) => item,
      );
  for (final operation in ['create', 'update', 'delete']) {
    test('$operation completion after close does not emit or reload', () async {
      final repository = _DelayedMutationRepository();
      final subject = cubit(repository);
      final pending = switch (operation) {
        'create' => subject.create(5),
        'update' => subject.update(1, 5),
        _ => subject.delete(1),
      };
      await subject.close();
      repository.finished.complete();
      expect(await pending, isTrue);
      expect(repository.requests, isEmpty);
    });
  }
  test('load completion after close is ignored', () async {
    final repository = _Repository()..delay = true;
    final subject = cubit(repository);
    final loading = subject.load();
    await subject.close();
    repository.requests.single.complete(Success(_page([1, 2])));
    await loading;
  });
  test('newer load supersedes an older request', () async {
    final repository = _Repository()..delay = true;
    final subject = cubit(repository);
    addTearDown(subject.close);
    final old = subject.load();
    final recent = subject.load();
    repository.requests.last.complete(Success(_page([3, 4])));
    await recent;
    repository.requests.first.complete(Success(_page([1, 2])));
    await old;
    expect(subject.state.items, [3, 4]);
  });
  test(
    'delete during partial pagination reloads and does not skip records',
    () async {
      final repository = _Repository();
      final subject = cubit(repository);
      addTearDown(subject.close);
      await subject.load();
      await subject.delete(1);
      expect(subject.state.items, [2, 3]);
      await subject.loadMore();
      expect(subject.state.items, [2, 3, 4]);
      expect(subject.state.hasMore, isFalse);
    },
  );
  test('create and update respect the server ordering after reload', () async {
    final subject = cubit(_Repository());
    addTearDown(subject.close);
    await subject.load();
    await subject.create(0);
    expect(subject.state.items, [0, 1]);
    await subject.update(0, 9);
    expect(subject.state.items, [1, 2]);
  });
  test(
    'failed reload preserves mutation success and discards stale pagination',
    () async {
      final repository = _Repository();
      final subject = cubit(repository);
      addTearDown(subject.close);
      await subject.load();
      repository.fail = true;
      expect(await subject.delete(1), isTrue);
      expect(subject.state.hasMore, isFalse);
      expect(subject.state.error, isA<NetworkFailure>());
      repository.fail = false;
      await subject.load();
      expect(subject.state.items, [2, 3]);
    },
  );
  test('load more completion after close is ignored', () async {
    final repository = _Repository();
    final subject = cubit(repository);
    await subject.load();
    repository.delay = true;
    final loading = subject.loadMore();
    await subject.close();
    repository.requests.single.complete(Success(_page([3, 4], page: 1)));
    await loading;
  });
}

class _DelayedMutationRepository extends _Repository {
  final finished = Completer<void>();
  @override
  Future<Result<int>> create(int draft) async {
    await finished.future;
    return Success(draft);
  }

  @override
  Future<Result<int>> update(int id, int draft) => create(draft);
  @override
  Future<Result<void>> delete(int id) async {
    await finished.future;
    return const Success(null);
  }
}

PageResult<int> _page(List<int> content, {int page = 0, int total = 4}) =>
    PageResult(
      content: content,
      page: page,
      size: 2,
      totalElements: total,
      totalPages: (total / 2).ceil(),
    );

class _Repository
    implements
        BaseCrudRepository<
          int,
          int,
          QueryRequest,
          QueryRequest,
          PageResult<int>,
          int,
          int
        > {
  final items = [1, 2, 3, 4];
  final requests = <Completer<Result<PageResult<int>>>>[];
  bool delay = false;
  bool fail = false;
  @override
  Future<Result<PageResult<int>>> queryPage(QueryRequest query) {
    if (delay) {
      final request = Completer<Result<PageResult<int>>>();
      requests.add(request);
      return request.future;
    }
    return Future.value(
      fail
          ? const FailureResult(NetworkFailure())
          : Success(
              _page(
                items.skip(query.page * query.size).take(query.size).toList(),
                page: query.page,
                total: items.length,
              ),
            ),
    );
  }

  @override
  Future<Result<int>> create(int draft) async {
    items.add(draft);
    items.sort();
    return Success(draft);
  }

  @override
  Future<Result<int>> update(int id, int draft) async {
    items.remove(id);
    return create(draft);
  }

  @override
  Future<Result<void>> delete(int id) async {
    items.remove(id);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
