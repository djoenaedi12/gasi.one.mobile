import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_plugin_attendance/gasione_plugin_attendance.dart';

PageResult<int> _page(List<int> items, {int page = 0, int totalPages = 1}) =>
    PageResult(
      content: items,
      page: page,
      size: 10,
      totalElements: items.length,
      totalPages: totalPages,
    );
void main() {
  test(
    'new search ignores late responses and keeps separate mode queries',
    () async {
      final old = Completer<Result<PageResult<int>>>();
      final controller = RequestListController<int>(
        mode: RequestMode.submission,
        load: (query) async =>
            query.search.isEmpty ? old.future : Success(_page([2])),
      );
      addTearDown(controller.dispose);
      final first = controller.refresh();
      await controller.setQuery(
        search: 'new',
        filters: {'status': 'approved'},
        sort: ['id,DESC'],
      );
      old.complete(Success(_page([1])));
      await first;
      expect(controller.items, [2]);
      expect(controller.query.search, 'new');
      expect(controller.query.filters, {'status': 'approved'});
      expect(controller.query.sort, ['id,DESC']);
    },
  );
  test('pagination failure keeps rows and retries the same page', () async {
    var failed = false;
    final pages = <int>[];
    final controller = RequestListController<int>(
      mode: RequestMode.approval,
      load: (query) async {
        pages.add(query.page);
        if (query.page == 0) return Success(_page([1], totalPages: 2));
        if (!failed) {
          failed = true;
          return const FailureResult(NetworkFailure());
        }
        return Success(_page([2], page: 1, totalPages: 2));
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.nextPage();
    expect(controller.items, [1]);
    expect(controller.failure, isA<NetworkFailure>());
    await controller.nextPage();
    expect(controller.items, [1, 2]);
    expect(pages, [0, 1, 1]);
    expect(controller.hasNext, false);
  });
  test('session clear invalidates pending reads immediately', () async {
    final pending = Completer<Result<PageResult<int>>>();
    final controller = RequestListController<int>(
      mode: RequestMode.submission,
      load: (_) => pending.future,
    );
    addTearDown(controller.dispose);
    final result = controller.refresh();
    controller.clear();
    pending.complete(Success(_page([7])));
    await result;
    expect(controller.items, isEmpty);
    expect(controller.initialized, false);
  });
  test(
    'bulk prevents duplicate requests and retry excludes successful items',
    () async {
      final gate = Completer<void>();
      var failSecond = true;
      final calls = <int>[];
      final selection = RequestSelectionController<int>(
        idOf: (i) => i,
        canSelect: (i) => i != 3,
        canExecute: (item, action) => item != 4,
        execute: (item, action, remark) async {
          calls.add(item);
          await gate.future;
          return item == 2 && failSecond
              ? const FailureResult(NetworkFailure())
              : const Success<void>(null);
        },
      );
      addTearDown(selection.dispose);
      selection.selectAll([1, 2, 3, 4]);
      expect(selection.selectedIds, {1, 2, 4});
      final first = selection.run(WorkflowAction.approve);
      expect(identical(first, selection.run(WorkflowAction.approve)), true);
      gate.complete();
      final result = await first;
      expect(result.succeeded, {1});
      expect(result.failures.keys, {2, 4});
      expect(calls, [1, 2]);
      expect(selection.selectedIds, {2, 4});
      failSecond = false;
      await selection.run(WorkflowAction.reject);
      expect(calls, [1, 2, 2]);
      selection.done();
      expect(selection.selecting, false);
      expect(selection.selectedIds, isEmpty);
    },
  );
  test('session clear stops bulk before another item is sent', () async {
    final gate = Completer<Result<void>>();
    final calls = <int>[];
    final selection = RequestSelectionController<int>(
      idOf: (i) => i,
      canSelect: (_) => true,
      canExecute: (_, _) => true,
      execute: (item, _, _) {
        calls.add(item);
        return gate.future;
      },
    );
    addTearDown(selection.dispose);
    selection.selectAll([1, 2]);
    final pending = selection.run(WorkflowAction.approve);
    await Future<void>.delayed(Duration.zero);
    selection.clear();
    gate.complete(const Success<void>(null));
    await pending;
    expect(calls, [1]);
    expect(selection.selectedIds, isEmpty);
  });
}
